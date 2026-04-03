-- ModuleScript: ServerScriptService/Services/RoundService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Enums      = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local Utility    = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utility"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local RoundConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("RoundConfig"))

-- Remotes
local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local RoundState    = Remotes:WaitForChild("RoundState")
local ShowChoices   = Remotes:WaitForChild("ShowChoices")
local SubmitChoice  = Remotes:WaitForChild("SubmitChoice")
local CombatInput   = Remotes:WaitForChild("CombatInput")
local HUDMessage    = Remotes:WaitForChild("HUDMessage")
local SyncDarkness  = Remotes:WaitForChild("SyncDarkness")

-- Сервисы (инжектируются через Init)
local PlayerStateService
local ChoiceService
local TeleportServiceLocal
local TeamService
local CombatService
local RewardService
local CelebrationService
local ValidationService

local RoundService = {}

-- ══════════════════════════════════════════════════
--  ЦЕНТРАЛЬНОЕ СОСТОЯНИЕ РАУНДА
-- ══════════════════════════════════════════════════
local roundState = {
	Phase       = Enums.Phase.Intermission,
	RoundNumber = 0,
	CurrentPair = nil,   -- { Left = entry, Right = entry }
	Winners     = "Draw",
	IsActive    = false,
}

-- Rate limiter для CombatInput
local combatRateLimiter = {}  -- [userId] = timestamp

-- ══════════════════════════════════════════════════
--  УТИЛИТЫ БРОДКАСТА
-- ══════════════════════════════════════════════════

local function broadcast(remote, data)
	remote:FireAllClients(data)
end

local function broadcastPhase(phase, extraData)
	roundState.Phase = phase
	local packet = { Phase = phase, Data = extraData or {} }
	RoundState:FireAllClients(packet)
	print(string.format("[RoundService] Фаза: %s", phase))
end

local function broadcastHUD(message, color)
	HUDMessage:FireAllClients({
		Message = message,
		Color   = color or Color3.fromRGB(255, 255, 255),
	})
end

local function broadcastTimer(phase, remaining)
	RoundState:FireAllClients({
		Phase = phase,
		Timer = math.max(0, math.floor(remaining)),
	})
end

-- ══════════════════════════════════════════════════
--  ВСПОМОГАТЕЛЬНЫЕ
-- ══════════════════════════════════════════════════

local function getEligiblePlayers()
	local result = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
			table.insert(result, p)
		end
	end
	return result
end

local function getZone(name)
	local arena = workspace:FindFirstChild("Arena")
	if not arena then return nil end
	return arena:FindFirstChild(name)
end

local function isInsidePart(part, position)
	if not part or not part:IsA("BasePart") then return false end
	local local_p = part.CFrame:PointToObjectSpace(position)
	local half    = part.Size / 2
	return math.abs(local_p.X) < half.X
		and math.abs(local_p.Y) < half.Y
		and math.abs(local_p.Z) < half.Z
end

-- ══════════════════════════════════════════════════
--  ОБРАБОТЧИКИ СОБЫТИЙ
-- ══════════════════════════════════════════════════

local function onSubmitChoice(player, payload)
	local allStates = PlayerStateService.GetAllStates()
	local ok, reason = ValidationService.ValidateSubmitChoice(
		player, payload, roundState, allStates
	)
	if not ok then
		print(string.format("[RoundService] SubmitChoice отклонён (%s): %s",
			player.Name, reason))
		return
	end
	PlayerStateService.SetSelectedSide(player, payload.Side)
	print(string.format("[RoundService] %s выбрал: %s", player.Name, payload.Side))
end

local function onCombatInput(player, payload)
	local uid = player.UserId
	local now = os.clock()
	-- Глобальный rate limit: не чаще 10 раз/сек
	if (combatRateLimiter[uid] or 0) + 0.1 > now then return end
	combatRateLimiter[uid] = now

	local allStates = PlayerStateService.GetAllStates()
	local ok, reason = ValidationService.ValidateCombatInput(
		player, payload, roundState, allStates
	)
	if not ok then return end

	CombatService.ProcessAction(player, payload)
end

local function onPlayerRemoving(player)
	if roundState.IsActive then
		PlayerStateService.SetAlive(player, false)
		PlayerStateService.SetInRound(player, false)
		print(string.format("[RoundService] %s вышел во время раунда.", player.Name))
	end
end

-- ══════════════════════════════════════════════════
--  ФАЗЫ РАУНДА
-- ══════════════════════════════════════════════════

-- ── INTERMISSION ──────────────────────────────────
local function phaseIntermission()
	broadcastPhase(Enums.Phase.Intermission, {
		TestMode = GameConfig.TEST_MODE,
	})

	local total = GameConfig.INTERMISSION_TIME
	print(string.format("[RoundService] Интермиссия началась. Нужно игроков: %d",
		GameConfig.MIN_PLAYERS))

	for elapsed = 1, total do
		task.wait(1)
		local count     = #Players:GetPlayers()
		local remaining = total - elapsed
		print(string.format("[RoundService] Интермиссия: %d/%d сек, игроков: %d",
			elapsed, total, count))
		broadcastTimer(Enums.Phase.Intermission, remaining)

		if count >= GameConfig.MIN_PLAYERS then
			if remaining <= 5 and remaining > 0 then
				broadcastHUD(
					"Раунд начнётся через " .. remaining .. "...",
					Color3.fromRGB(255, 220, 0)
				)
			elseif remaining <= 0 then
				break
			end
		else
			broadcastHUD(
				"Нужно игроков: " .. GameConfig.MIN_PLAYERS .. " (сейчас " .. count .. ")",
				Color3.fromRGB(200, 200, 200)
			)
		end
	end

	local finalCount = #Players:GetPlayers()
	print(string.format("[RoundService] Интермиссия закончилась. Игроков: %d, нужно: %d",
		finalCount, GameConfig.MIN_PLAYERS))
	return finalCount >= GameConfig.MIN_PLAYERS
end

-- ── TELEPORT TO PRE-ARENA ──────────────────────────
local function phaseTeleportToPreArena(participants)
	broadcastPhase(Enums.Phase.TeleportToPreArena)
	broadcastHUD("Телепортация на арену...", Color3.fromRGB(100, 200, 255))

	-- Сохраняем позиции лобби
	TeleportServiceLocal.SaveAllPositions(participants)

	-- Сбрасываем стейт игроков
	for _, p in ipairs(participants) do
		PlayerStateService.ResetForRound(p)
		PlayerStateService.SetInRound(p, true)
	end

	-- Телепортируем
	TeleportServiceLocal.TeleportToPreArena(participants)

	task.wait(GameConfig.PRE_ARENA_WAIT_TIME)
end

-- ── REVEAL CHOICE A ────────────────────────────────
local function phaseRevealChoiceA(pair)
	broadcastPhase(Enums.Phase.RevealChoiceA, {
		Text   = pair.Left.Text,
		Color  = pair.Left.Color,
		Image  = pair.Left.Image  or 0,
		SfxKey = pair.Left.RevealSfxKey or "RevealSting1",
	})
	broadcastHUD("Вариант A: " .. pair.Left.Text, pair.Left.Color)
	task.wait(GameConfig.REVEAL_A_TIME)
end

-- ── REVEAL CHOICE B ────────────────────────────────
local function phaseRevealChoiceB(pair)
	broadcastPhase(Enums.Phase.RevealChoiceB, {
		Text   = pair.Right.Text,
		Color  = pair.Right.Color,
		Image  = pair.Right.Image  or 0,
		SfxKey = pair.Right.RevealSfxKey or "RevealSting2",
	})
	broadcastHUD("Вариант B: " .. pair.Right.Text, pair.Right.Color)
	task.wait(GameConfig.REVEAL_B_TIME)
end

-- ── DARK CHOICE ────────────────────────────────────
local function phaseDarkChoice(pair)
	-- Включаем темноту на клиентах
	SyncDarkness:FireAllClients({ Dark = true })

	broadcastPhase(Enums.Phase.DarkChoice, {
		LeftText   = pair.Left.Text,
		RightText  = pair.Right.Text,
		LeftColor  = pair.Left.Color,
		RightColor = pair.Right.Color,
		LeftImage  = pair.Left.Image  or 0,
		RightImage = pair.Right.Image or 0,
		Duration   = GameConfig.DARK_CHOICE_TIME,
	})
	broadcastHUD("Выбери сторону!", Color3.fromRGB(255, 255, 100))

	-- Таймер выбора
	local duration = GameConfig.DARK_CHOICE_TIME
	for elapsed = 1, duration do
		task.wait(1)
		local remaining = duration - elapsed
		broadcastTimer(Enums.Phase.DarkChoice, remaining)
	end

	-- ── LockChoice: фиксируем выборы ──────────────
	broadcastPhase(Enums.Phase.LockChoice)
	broadcastHUD("Выбор зафиксирован!", Color3.fromRGB(200, 200, 200))

	-- Зональная проверка: физическое присутствие перебивает UI-выбор
	local leftZone  = getZone("ChoiceLeftZone")
	local rightZone = getZone("ChoiceRightZone")

	if leftZone or rightZone then
		for _, player in ipairs(Players:GetPlayers()) do
			local hrp = Utility.GetHumanoidRootPart(player)
			if not hrp then continue end
			local pos = hrp.Position

			if leftZone  and isInsidePart(leftZone,  pos) then
				PlayerStateService.SetSelectedSide(player, Enums.Team.Left)
			elseif rightZone and isInsidePart(rightZone, pos) then
				PlayerStateService.SetSelectedSide(player, Enums.Team.Right)
			end
		end
	end

	task.wait(0.5)
end

-- ── ASSIGN TEAMS ───────────────────────────────────
local function phaseAssignTeams(participants)
	broadcastPhase(Enums.Phase.AssignTeams)

	local allStates = PlayerStateService.GetAllStates()
	local teams     = TeamService.AssignTeams(participants, allStates)

	-- Обновляем стейт игроков с командой
	for _, p in ipairs(teams.Left) do
		PlayerStateService.SetTeam(p, Enums.Team.Left)
	end
	for _, p in ipairs(teams.Right) do
		PlayerStateService.SetTeam(p, Enums.Team.Right)
	end

	print(string.format("[RoundService] Команды: Left=%d, Right=%d",
		#teams.Left, #teams.Right))
	broadcastHUD("Команды сформированы!", Color3.fromRGB(100, 255, 100))
	task.wait(1)
	return teams
end

-- ── TELEPORT TO BATTLE ─────────────────────────────
local function phaseTeleportToBattle(teams)
	broadcastPhase(Enums.Phase.TeleportToBattle)
	broadcastHUD("На позиции!", Color3.fromRGB(255, 150, 0))

	TeleportServiceLocal.TeleportTeamToBattle(teams.Left,  "Left")
	TeleportServiceLocal.TeleportTeamToBattle(teams.Right, "Right")

	task.wait(1.5)
end

-- ── BATTLE ─────────────────────────────────────────
local function phaseBattle(allParticipants)
	-- Инициализируем HP на сервере
	CombatService.InitializeHP(allParticipants)

	-- Убираем темноту (если вдруг осталась)
	SyncDarkness:FireAllClients({ Dark = false })

	broadcastPhase(Enums.Phase.Battle, {
		Duration = GameConfig.BATTLE_TIME,
	})
	broadcastHUD("БОЙ!", Color3.fromRGB(255, 50, 50))

	local duration      = GameConfig.BATTLE_TIME
	local checkInterval = 0.5
	local elapsed       = 0
	local winner        = nil

	while elapsed < duration do
		task.wait(checkInterval)
		elapsed = elapsed + checkInterval

		-- Проверка досрочной победы
		local freshStates = PlayerStateService.GetAllStates()
		local earlyWin    = CombatService.CheckWinCondition(freshStates)
		if earlyWin ~= nil then
			winner = earlyWin
			print(string.format("[RoundService] Досрочная победа: %s (%.1f сек)", winner, elapsed))
			break
		end

		-- Таймер клиентам каждую секунду
		if math.floor(elapsed) ~= math.floor(elapsed - checkInterval) then
			broadcastTimer(Enums.Phase.Battle, duration - elapsed)
		end
	end

	-- Если досрочной победы не было — определяем победителя по статистике
	if not winner then
		local freshStates = PlayerStateService.GetAllStates()
		winner = TeamService.ResolveWinner(freshStates, RoundConfig.WINNER_RESOLVE_ORDER)
		print(string.format("[RoundService] Победитель по таймауту: %s", winner))
	end

	return winner
end

-- ── VICTORY ────────────────────────────────────────
local function phaseVictory(winner)
	broadcastPhase(Enums.Phase.Victory, { Winner = winner })

	if winner == "Draw" then
		broadcastHUD("НИЧЬЯ!", Color3.fromRGB(200, 200, 200))
	else
		broadcastHUD("Победила команда " .. winner .. "!", Color3.fromRGB(255, 220, 0))
	end

	task.wait(1.5)
end

-- ── CELEBRATION ────────────────────────────────────
local function phaseCelebration(winner, allParticipants)
	broadcastPhase(Enums.Phase.Celebration)

	-- Начисляем награды
	local allStates = PlayerStateService.GetAllStates()
	RewardService.GrantRoundRewards(allParticipants, winner, PlayerStateService)

	-- Анимация победы + результат UI
	CelebrationService.Announce(
		allParticipants,
		winner,
		TeamService.GetTeam(winner),
		PlayerStateService
	)

	task.wait(GameConfig.CELEBRATION_TIME)
end

-- ── RETURN TO LOBBY ────────────────────────────────
local function phaseReturnToLobby(allParticipants)
	broadcastPhase(Enums.Phase.ReturnToLobby)
	broadcastHUD("Возвращаемся в лобби...", Color3.fromRGB(150, 150, 255))

	-- Убираем темноту на всякий случай
	SyncDarkness:FireAllClients({ Dark = false })

	task.wait(GameConfig.RETURN_DELAY)
	TeleportServiceLocal.ReturnAllToLobby(allParticipants)
	task.wait(1)
end

-- ── CLEANUP ────────────────────────────────────────
local function phaseCleanup()
	broadcastPhase(Enums.Phase.Cleanup)

	TeamService.Reset()
	combatRateLimiter     = {}
	roundState.IsActive   = false
	roundState.CurrentPair = nil
	roundState.Winners    = "Draw"

	-- Сбрасываем стейт всех игроков
	for _, p in ipairs(Players:GetPlayers()) do
		PlayerStateService.ResetForRound(p)
	end

	task.wait(0.5)
end

-- ══════════════════════════════════════════════════
--  ГЛАВНЫЙ ЦИКЛ
-- ══════════════════════════════════════════════════

function RoundService.StartLoop()
	print("[RoundService] Главный цикл запущен.")

	while true do
		roundState.IsActive = false

		-- ── 1. Интермиссия ──
		local canStart = phaseIntermission()
		if not canStart then
			task.wait(3)
			continue
		end

		-- ── 2. Собираем участников ──
		local participants = getEligiblePlayers()
		if #participants == 0 then
			task.wait(3)
			continue
		end

		roundState.IsActive  = true
		roundState.RoundNumber = roundState.RoundNumber + 1
		print(string.format("[RoundService] === Раунд %d ===", roundState.RoundNumber))

		-- ── 3. Выбираем пару вариантов ──
		local pair = ChoiceService.PickNextPair()
		roundState.CurrentPair = pair
		print(string.format("[RoundService] Пара: %s  VS  %s",
			pair.Left.Text, pair.Right.Text))

		-- ── 4. Телепортация на преарену ──
		phaseTeleportToPreArena(participants)

		-- ── 5. Показываем варианты по одному ──
		phaseRevealChoiceA(pair)
		phaseRevealChoiceB(pair)

		-- ── 6. Выбор в темноте ──
		phaseDarkChoice(pair)

		-- ── 7. Формируем команды ──
		local teams = phaseAssignTeams(participants)

		-- ── 8. Балансировка: если одна команда пуста ──
		if #teams.Left == 0 and #teams.Right > 0 then
			local moved = table.remove(teams.Right, 1)
			table.insert(teams.Left, moved)
			PlayerStateService.SetTeam(moved, Enums.Team.Left)
			print("[RoundService] Переместили игрока в Left для баланса.")
		elseif #teams.Right == 0 and #teams.Left > 0 then
			local moved = table.remove(teams.Left, 1)
			table.insert(teams.Right, moved)
			PlayerStateService.SetTeam(moved, Enums.Team.Right)
			print("[RoundService] Переместили игрока в Right для баланса.")
		elseif #teams.Left == 0 and #teams.Right == 0 then
			-- Совсем нет участников — пропускаем раунд
			warn("[RoundService] Обе команды пустые — пропускаем раунд.")
			phaseCleanup()
			continue
		end

		local allParticipants = TeamService.GetAllParticipants()

		-- ── 9. Телепортация к спавнам боя ──
		phaseTeleportToBattle(teams)

		-- ── 10. Бой ──
		local winner = phaseBattle(allParticipants)
		roundState.Winners = winner

		-- ── 11. Объявление победителя ──
		phaseVictory(winner)

		-- ── 12. Праздник победителей ──
		phaseCelebration(winner, allParticipants)

		-- ── 13. Возврат в лобби ──
		phaseReturnToLobby(allParticipants)

		-- ── 14. Очистка ──
		phaseCleanup()
	end
end

-- ══════════════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════════════

function RoundService.Init(pss, cs, tsl, ts, cbs, rs, cels, vs)
	PlayerStateService   = pss
	ChoiceService        = cs
	TeleportServiceLocal = tsl
	TeamService          = ts
	CombatService        = cbs
	RewardService        = rs
	CelebrationService   = cels
	ValidationService    = vs

	-- Подключаем ремоуты
	SubmitChoice.OnServerEvent:Connect(onSubmitChoice)
	CombatInput.OnServerEvent:Connect(onCombatInput)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	print("[RoundService] Initialized.")
end

function RoundService.GetRoundState()
	return roundState
end

return RoundService