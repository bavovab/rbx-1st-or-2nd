-- ModuleScript: ServerScriptService/Services/RoundService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local Utility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utility"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local RoundConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("RoundConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundState = Remotes:WaitForChild("RoundState")
local HUDMessage = Remotes:WaitForChild("HUDMessage")
local SyncDarkness = Remotes:WaitForChild("SyncDarkness")
local SubmitChoice = Remotes:WaitForChild("SubmitChoice")
local CombatInput = Remotes:WaitForChild("CombatInput")

local PlayerStateService
local ChoiceService
local TeleportServiceLocal
local TeamService
local CombatService
local RewardService
local CelebrationService
local ValidationService

local RoundService = {}

local roundState = {
	Phase = Enums.Phase.Intermission,
	RoundNumber = 0,
	CurrentPair = nil,
	Winners = "Draw",
	IsActive = false,
}

local combatRateLimiter = {}

local function broadcastPhase(phase, extraData)
	roundState.Phase = phase
	RoundState:FireAllClients({
		Phase = phase,
		Data = extraData or {},
	})
	print(string.format("[RoundService] Phase -> %s", tostring(phase)))
end

local function broadcastTimer(phase, remaining)
	RoundState:FireAllClients({
		Phase = phase,
		Timer = math.max(0, math.floor(remaining)),
	})
end

local function broadcastHUD(message, color)
	HUDMessage:FireAllClients({
		Message = message,
		Color = color or Color3.fromRGB(255, 255, 255),
	})
end

local function getEligiblePlayers()
	local participants = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local hum = Utility.GetHumanoid(player)
		if hum then
			table.insert(participants, player)
		end
	end
	return participants
end

local function getArenaPart(name)
	local arena = workspace:FindFirstChild("Arena")
	if not arena then return nil end
	return arena:FindFirstChild(name)
end

local function isInsidePart(part, position)
	if not part or not part:IsA("BasePart") then return false end
	local localPos = part.CFrame:PointToObjectSpace(position)
	local half = part.Size * 0.5
	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y
		and math.abs(localPos.Z) <= half.Z
end

local function onSubmitChoice(player, payload)
	local allStates = PlayerStateService.GetAllStates()
	local ok, reason = ValidationService.ValidateSubmitChoice(player, payload, roundState, allStates)
	if not ok then
		print(string.format("[RoundService] SubmitChoice rejected for %s: %s", player.Name, tostring(reason)))
		return
	end
	PlayerStateService.SetSelectedSide(player, payload.Side)
	print(string.format("[RoundService] %s selected side: %s", player.Name, tostring(payload.Side)))
end

local function onCombatInput(player, payload)
	local uid = player.UserId
	local now = os.clock()
	if (combatRateLimiter[uid] or 0) + 0.1 > now then return end
	combatRateLimiter[uid] = now

	local allStates = PlayerStateService.GetAllStates()
	local ok = ValidationService.ValidateCombatInput(player, payload, roundState, allStates)
	if not ok then return end

	CombatService.ProcessAction(player, payload)
end

local function onPlayerRemoving(player)
	if not roundState.IsActive then return end
	PlayerStateService.SetAlive(player, false)
	PlayerStateService.SetInRound(player, false)
	print(string.format("[RoundService] %s left during active round.", player.Name))
end

-- ══════════════════════════════════════════════════
-- ФАЗЫ
-- ══════════════════════════════════════════════════

local function phaseIntermission()
	broadcastPhase(Enums.Phase.Intermission, {
		TestMode = GameConfig.TEST_MODE,
	})

	local total = GameConfig.INTERMISSION_TIME

	for elapsed = 1, total do
		task.wait(1)
		local count = #Players:GetPlayers()
		local remaining = total - elapsed
		broadcastTimer(Enums.Phase.Intermission, remaining)

		if count >= GameConfig.MIN_PLAYERS then
			if remaining <= 5 and remaining > 0 then
				broadcastHUD("Раунд начнётся через " .. remaining .. "...", Color3.fromRGB(255, 220, 0))
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

	return #Players:GetPlayers() >= GameConfig.MIN_PLAYERS
end

local function phaseTeleportToPreArena(participants)
	broadcastPhase(Enums.Phase.TeleportToPreArena)
	broadcastHUD("Телепортация на арену...", Color3.fromRGB(100, 200, 255))

	TeleportServiceLocal.SaveAllPositions(participants)

	for _, player in ipairs(participants) do
		PlayerStateService.ResetForRound(player)
		PlayerStateService.SetInRound(player, true)
	end

	TeleportServiceLocal.TeleportToPreArena(participants)
	task.wait(GameConfig.PRE_ARENA_WAIT_TIME)
end

local function phaseRevealChoiceA(pair)
	broadcastPhase(Enums.Phase.RevealChoiceA, {
		Text  = pair.Left.Text,
		Color = pair.Left.Color,
		Image = pair.Left.Image or 0,
		Music = pair.Left.Music or 0,   -- ← музыка варианта A
	})
	broadcastHUD("Вариант A: " .. pair.Left.Text, pair.Left.Color)
	task.wait(GameConfig.REVEAL_A_TIME)
end

local function phaseRevealChoiceB(pair)
	broadcastPhase(Enums.Phase.RevealChoiceB, {
		Text  = pair.Right.Text,
		Color = pair.Right.Color,
		Image = pair.Right.Image or 0,
		Music = pair.Right.Music or 0,  -- ← музыка варианта B
	})
	broadcastHUD("Вариант B: " .. pair.Right.Text, pair.Right.Color)
	task.wait(GameConfig.REVEAL_B_TIME)
end

local function phaseDarkChoice(pair)
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

	local duration = GameConfig.DARK_CHOICE_TIME
	for elapsed = 1, duration do
		task.wait(1)
		local remaining = duration - elapsed
		broadcastTimer(Enums.Phase.DarkChoice, remaining)
	end

	broadcastPhase(Enums.Phase.LockChoice)
	broadcastHUD("Выбор зафиксирован!", Color3.fromRGB(200, 200, 200))

	local leftZone  = getArenaPart("ChoiceLeftZone")
	local rightZone = getArenaPart("ChoiceRightZone")

	if leftZone or rightZone then
		for _, player in ipairs(Players:GetPlayers()) do
			local hrp = Utility.GetHumanoidRootPart(player)
			if not hrp then continue end
			local pos = hrp.Position
			if leftZone and isInsidePart(leftZone, pos) then
				PlayerStateService.SetSelectedSide(player, Enums.Team.Left)
			elseif rightZone and isInsidePart(rightZone, pos) then
				PlayerStateService.SetSelectedSide(player, Enums.Team.Right)
			end
		end
	end

	task.wait(0.5)
end

local function phaseAssignTeams(participants)
	broadcastPhase(Enums.Phase.AssignTeams)

	local allStates = PlayerStateService.GetAllStates()
	local teams = TeamService.AssignTeams(participants, allStates)

	for _, player in ipairs(teams.Left) do
		PlayerStateService.SetTeam(player, Enums.Team.Left)
	end

	for _, player in ipairs(teams.Right) do
		PlayerStateService.SetTeam(player, Enums.Team.Right)
	end

	print(string.format("[RoundService] Teams by choice: Left=%d, Right=%d", #teams.Left, #teams.Right))
	broadcastHUD("Команды сформированы!", Color3.fromRGB(100, 255, 100))
	task.wait(1)

	return teams
end

local function phaseTeleportToBattle(teams)
	broadcastPhase(Enums.Phase.TeleportToBattle)
	broadcastHUD("На позиции!", Color3.fromRGB(255, 150, 0))

	if #teams.Left > 0 then
		TeleportServiceLocal.TeleportTeamToBattle(teams.Left, "Left")
	end
	if #teams.Right > 0 then
		TeleportServiceLocal.TeleportTeamToBattle(teams.Right, "Right")
	end

	task.wait(1.5)
end

local function phaseBattle(allParticipants)
	-- Инициализируем HP и выдаём оружие всем участникам
	CombatService.InitializeHP(allParticipants)

	broadcastPhase(Enums.Phase.Battle, {
		Duration = GameConfig.BATTLE_TIME,
	})
	broadcastHUD("⚔️ БИТВА!", Color3.fromRGB(255, 50, 50))

	local startTime = os.clock()
	local winner = nil

	while true do
		task.wait(0.5)

		local elapsed = os.clock() - startTime
		local remaining = math.max(0, math.ceil(GameConfig.BATTLE_TIME - elapsed))

		-- Тик таймера БЕЗ поля Phase — клиент просто обновляет цифру
		RoundState:FireAllClients({ Timer = remaining })

		local freshStates = PlayerStateService.GetAllStates()
		local earlyWin = CombatService.CheckWinCondition(freshStates)
		if earlyWin ~= nil then
			winner = earlyWin
			print(string.format("[RoundService] Early winner: %s", tostring(winner)))
			break
		end

		if elapsed >= GameConfig.BATTLE_TIME then
			print("[RoundService] Battle timer finished.")
			break
		end
	end

	if not winner then
		local freshStates = PlayerStateService.GetAllStates()
		local resolveOrder = RoundConfig.WINNER_RESOLVE_ORDER
			or RoundConfig.TIMER_WIN_PRIORITY
			or { "AliveCount", "TotalHP", "Draw" }
		winner = TeamService.ResolveWinner(freshStates, resolveOrder)
		print(string.format("[RoundService] Resolved winner: %s", tostring(winner)))
	end

	if not winner then
		winner = "Draw"
		warn("[RoundService] Winner was nil after ResolveWinner; fallback to Draw.")
	end

	return winner
end

local function phaseVictory(winner)
	broadcastPhase(Enums.Phase.Victory, { Winner = winner })

	if winner == "Draw" then
		broadcastHUD("НИЧЬЯ!", Color3.fromRGB(200, 200, 200))
	else
		broadcastHUD("Победила команда " .. tostring(winner) .. "!", Color3.fromRGB(255, 220, 0))
	end

	task.wait(1.5)
end

local function phaseCelebration(winner, allParticipants)
	broadcastPhase(Enums.Phase.Celebration)

	-- CombatService передаётся чтобы умершие победители тоже получили награду
	RewardService.GrantRoundRewards(allParticipants, winner, PlayerStateService, CombatService)
	CelebrationService.Announce(
		allParticipants,
		winner,
		TeamService.GetTeam(winner),
		PlayerStateService,
		CombatService
	)

	task.wait(GameConfig.CELEBRATION_TIME)
end

local function phaseReturnToLobby(allParticipants)
	broadcastPhase(Enums.Phase.ReturnToLobby)
	broadcastHUD("Возвращаемся в лобби...", Color3.fromRGB(150, 150, 255))
	SyncDarkness:FireAllClients({ Dark = false })

	-- Забираем оружие у всех перед возвратом
	CombatService.EndRound(allParticipants)

	task.wait(GameConfig.RETURN_DELAY)
	TeleportServiceLocal.ReturnAllToLobby(allParticipants)
	task.wait(1)
end

local function phaseCleanup()
	broadcastPhase(Enums.Phase.Cleanup)
	TeamService.Reset()
	combatRateLimiter = {}
	roundState.IsActive = false
	roundState.CurrentPair = nil
	roundState.Winners = "Draw"
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerStateService.ResetForRound(player)
	end
	task.wait(0.5)
end

-- ══════════════════════════════════════════════════
-- ГЛАВНЫЙ ЦИКЛ
-- ══════════════════════════════════════════════════

function RoundService.StartLoop()
	print("[RoundService] Main loop started.")

	while true do
		roundState.IsActive = false

		local canStart = phaseIntermission()
		if not canStart then task.wait(3); continue end

		local participants = getEligiblePlayers()
		if #participants == 0 then task.wait(3); continue end

		roundState.IsActive = true
		roundState.RoundNumber += 1
		print(string.format("[RoundService] === Round %d ===", roundState.RoundNumber))

		local pair = ChoiceService.PickNextPair()
		roundState.CurrentPair = pair
		print(string.format("[RoundService] Pair: %s vs %s", pair.Left.Text, pair.Right.Text))

		phaseTeleportToPreArena(participants)
		phaseRevealChoiceA(pair)
		phaseRevealChoiceB(pair)
		phaseDarkChoice(pair)

		local teams = phaseAssignTeams(participants)
		local allParticipants = TeamService.GetAllParticipants()

		if #allParticipants == 0 then
			warn("[RoundService] No players assigned to any team. Returning to lobby.")
			phaseReturnToLobby(participants)
			phaseCleanup()
			continue
		end

		phaseTeleportToBattle(teams)

		local winner = phaseBattle(allParticipants)
		roundState.Winners = winner

		phaseVictory(winner)
		phaseCelebration(winner, allParticipants)
		phaseReturnToLobby(allParticipants)
		phaseCleanup()
	end
end

-- ══════════════════════════════════════════════════
-- INIT
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

	SubmitChoice.OnServerEvent:Connect(onSubmitChoice)
	CombatInput.OnServerEvent:Connect(onCombatInput)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	print("[RoundService] Initialized.")
end

function RoundService.GetRoundState()
	return roundState
end

return RoundService