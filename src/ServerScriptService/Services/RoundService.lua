-- ModuleScript: ServerScriptService/Services/RoundService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Config  = ReplicatedStorage:WaitForChild("Config")

local Enums      = require(Shared:WaitForChild("Enums"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local RoundConfig = require(Config:WaitForChild("RoundConfig"))
local Utility    = require(Shared:WaitForChild("Utility"))

local PlayerStateService
local ChoiceService
local TeleportServiceLocal
local TeamService
local CombatService
local RewardService
local CelebrationService
local ValidationService

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local RoundState   = Remotes:WaitForChild("RoundState")
local ShowChoices  = Remotes:WaitForChild("ShowChoices")
local SubmitChoice = Remotes:WaitForChild("SubmitChoice")
local CombatInput  = Remotes:WaitForChild("CombatInput")
local HUDMessage   = Remotes:WaitForChild("HUDMessage")
local SyncDarkness = Remotes:WaitForChild("SyncDarkness")

local RoundService = {}

local roundState = {
	Phase       = Enums.Phase.Intermission,
	RoundNumber = 0,
	CurrentPair = nil,
	Winners     = "Draw",
	IsActive    = false,
}

local combatRateLimiter = {}

local function broadcast(remote, ...)
	remote:FireAllClients(...)
end

local function broadcastPhase(phase, data)
	roundState.Phase = phase
	broadcast(RoundState, { Phase = phase, Data = data or {} })
end

local function broadcastHUD(message, color)
	HUDMessage:FireAllClients({ Message = message, Color = color })
end

local function getEligiblePlayers()
	local result = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(result, p)
			end
		end
	end
	return result
end

-- ── Combat input ──
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

-- ── Submit choice ──
local function onSubmitChoice(player, payload)
	local allStates = PlayerStateService.GetAllStates()
	local ok = ValidationService.ValidateSubmitChoice(player, payload, roundState, allStates)
	if not ok then return end
	PlayerStateService.SetSelectedSide(player, payload.Side)
end

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

	Players.PlayerRemoving:Connect(function(player)
		if roundState.IsActive then
			PlayerStateService.SetAlive(player, false)
			PlayerStateService.SetInRound(player, false)
		end
	end)

	print("[RoundService] Initialized.")
end

-- ════════════════════════════════════════════
--  PHASES
-- ════════════════════════════════════════════

local function phaseIntermission()
	broadcastPhase(Enums.Phase.Intermission, { TestMode = GameConfig.TEST_MODE })
	print("[RoundService] Интермиссия началась. Нужно игроков:", GameConfig.MIN_PLAYERS)
	local elapsed = 0
	while elapsed < GameConfig.INTERMISSION_TIME do
		task.wait(1)
		elapsed = elapsed + 1
		local count = #Players:GetPlayers()
		print(string.format("[RoundService] Интермиссия: %d/%d сек, игроков: %d",
			elapsed, GameConfig.INTERMISSION_TIME, count))
		local remaining = GameConfig.INTERMISSION_TIME - elapsed
		if count >= GameConfig.MIN_PLAYERS and remaining <= 5 then
			broadcastHUD("Раунд начнётся через " .. remaining .. "...", Color3.fromRGB(255,200,0))
		end
	end
	local count = #Players:GetPlayers()
	print(string.format("[RoundService] Интермиссия закончилась. Игроков: %d, нужно: %d", count, GameConfig.MIN_PLAYERS))
	return count >= GameConfig.MIN_PLAYERS
end

local function phaseTeleportToPreArena(participants)
	broadcastPhase(Enums.Phase.TeleportToPreArena)
	broadcastHUD("Телепортация на арену...", Color3.fromRGB(100,200,255))
	print("[RoundService] ТелепортТоПреАрена: участников", #participants)
	TeleportServiceLocal.SaveAllPositions(participants)
	TeleportServiceLocal.TeleportToPreArena(participants)
	for _, p in ipairs(participants) do
		PlayerStateService.ResetForRound(p)
		PlayerStateService.SetInRound(p, true)
	end
	task.wait(GameConfig.PRE_ARENA_WAIT_TIME or 3)
end

local function phaseRevealA(pair)
	print("[RoundService] RevealA:", pair.LeftText)
	broadcastPhase(Enums.Phase.RevealChoiceA, {
		Text  = pair.LeftText,
		Color = pair.LeftColor,
	})
	broadcastHUD("Выбор А: " .. pair.LeftText, pair.LeftColor)
	task.wait(GameConfig.REVEAL_A_TIME or 3)
end

local function phaseRevealB(pair)
	print("[RoundService] RevealB:", pair.RightText)
	broadcastPhase(Enums.Phase.RevealChoiceB, {
		Text  = pair.RightText,
		Color = pair.RightColor,
	})
	broadcastHUD("Выбор Б: " .. pair.RightText, pair.RightColor)
	task.wait(GameConfig.REVEAL_B_TIME or 3)
end

local function phaseDarkChoice(pair, participants)
	local duration = GameConfig.DARK_CHOICE_TIME or 10
	print("[RoundService] DarkChoice начался,", duration, "сек")
	SyncDarkness:FireAllClients({ Dark = true })
	broadcastPhase(Enums.Phase.DarkChoice, {
		LeftText   = pair.LeftText,
		RightText  = pair.RightText,
		LeftColor  = pair.LeftColor,
		RightColor = pair.RightColor,
		Duration   = duration,
	})
	broadcastHUD("Выбери сторону!", Color3.fromRGB(255,255,100))

	-- Countdown with timer sync
	for i = duration, 1, -1 do
		task.wait(1)
		broadcast(RoundState, { Phase = Enums.Phase.DarkChoice, Timer = i - 1 })
	end

	-- Lock
	print("[RoundService] LockChoice — читаем зоны")
	broadcastPhase(Enums.Phase.LockChoice)
	SyncDarkness:FireAllClients({ Dark = false })

	-- Zone resolution
	local arenaFolder = workspace:FindFirstChild("Arena")
	local leftZone    = arenaFolder and arenaFolder:FindFirstChild("ChoiceLeftZone")
	local rightZone   = arenaFolder and arenaFolder:FindFirstChild("ChoiceRightZone")

	if leftZone or rightZone then
		for _, player in ipairs(participants) do
			local hrp = Utility.GetHumanoidRootPart(player)
			if not hrp then continue end
			local pos = hrp.Position
			local function inZone(zone)
				if not zone or not zone:IsA("BasePart") then return false end
				local lp   = zone.CFrame:PointToObjectSpace(pos)
				local half = zone.Size / 2
				return math.abs(lp.X) < half.X
					and math.abs(lp.Y) < half.Y
					and math.abs(lp.Z) < half.Z
			end
			if inZone(leftZone) then
				PlayerStateService.SetSelectedSide(player, Enums.Team.Left)
			elseif inZone(rightZone) then
				PlayerStateService.SetSelectedSide(player, Enums.Team.Right)
			end
		end
	end

	task.wait(0.5)
end

local function phaseAssignTeams(participants)
	broadcastPhase(Enums.Phase.AssignTeams)
	local allStates = PlayerStateService.GetAllStates()
	local teams     = TeamService.AssignTeams(participants, allStates)

	-- ── Solo / TEST_MODE fix ──
	-- If one team is empty, move one player from the other side.
	-- In solo test this makes the single player fight "themselves"
	-- (they will be on Left, Right is empty → battle ends instantly as a draw,
	--  but the full round loop completes correctly).
	if #teams.Left == 0 and #teams.Right > 0 then
		local moved = table.remove(teams.Right, 1)
		table.insert(teams.Left, moved)
		PlayerStateService.SetTeam(moved, Enums.Team.Left)
		print("[RoundService] Solo fix: переместили игрока в Left")
	elseif #teams.Right == 0 and #teams.Left > 0 then
		local moved = table.remove(teams.Left, 1)
		table.insert(teams.Right, moved)
		PlayerStateService.SetTeam(moved, Enums.Team.Right)
		print("[RoundService] Solo fix: переместили игрока в Right")
	end

	-- Update state for everyone
	for _, p in ipairs(teams.Left)  do PlayerStateService.SetTeam(p, Enums.Team.Left)  end
	for _, p in ipairs(teams.Right) do PlayerStateService.SetTeam(p, Enums.Team.Right) end

	print(string.format("[RoundService] Команды: Left=%d Right=%d", #teams.Left, #teams.Right))

	-- Final guard: if STILL empty on either side, skip round
	if #teams.Left == 0 or #teams.Right == 0 then
		print("[RoundService] Невозможно создать две команды, пропуск")
		return nil
	end

	broadcastHUD("Команды сформированы!", Color3.fromRGB(100,255,100))
	task.wait(1)
	return teams
end

local function phaseTeleportToBattle(teams)
	broadcastPhase(Enums.Phase.TeleportToBattle)
	TeleportServiceLocal.TeleportTeamToBattle(teams.Left,  "Left")
	TeleportServiceLocal.TeleportTeamToBattle(teams.Right, "Right")
	task.wait(1.5)
end

local function phaseBattle(allParticipants)
	CombatService.InitializeHP(allParticipants)
	SyncDarkness:FireAllClients({ Dark = false })
	broadcastPhase(Enums.Phase.Battle, { Duration = GameConfig.BATTLE_TIME })
	broadcastHUD("БОЙ!", Color3.fromRGB(255,50,50))

	local elapsed     = 0
	local checkStep   = 0.5
	local winner      = nil

	while elapsed < GameConfig.BATTLE_TIME do
		task.wait(checkStep)
		elapsed = elapsed + checkStep
		local remaining = math.ceil(GameConfig.BATTLE_TIME - elapsed)
		broadcast(RoundState, { Timer = remaining })

		local w = CombatService.CheckWinCondition(PlayerStateService.GetAllStates())
		if w ~= nil then
			winner = w
			break
		end
	end

	if not winner then
		winner = TeamService.ResolveWinner(
			PlayerStateService.GetAllStates(),
			RoundConfig.WINNER_RESOLVE_ORDER
		)
	end

	return winner
end

local function phaseVictory(winner)
	broadcastPhase(Enums.Phase.Victory, { Winner = winner })
	if winner == "Draw" then
		broadcastHUD("Ничья!", Color3.fromRGB(200,200,200))
	else
		broadcastHUD("Победила команда " .. winner .. "!", Color3.fromRGB(255,220,0))
	end
	task.wait(1.5)
end

local function phaseCelebration(winner, allParticipants)
	broadcastPhase(Enums.Phase.Celebration)
	RewardService.GrantRoundRewards(allParticipants, winner, PlayerStateService)
	CelebrationService.Announce(allParticipants, winner, TeamService.GetTeam(winner), PlayerStateService)
	task.wait(GameConfig.CELEBRATION_TIME)
end

local function phaseReturnToLobby(allParticipants)
	broadcastPhase(Enums.Phase.ReturnToLobby)
	SyncDarkness:FireAllClients({ Dark = false })
	task.wait(GameConfig.RETURN_DELAY or 2)
	TeleportServiceLocal.ReturnAllToLobby(allParticipants)
	broadcastHUD("Возвращение в лобби...", Color3.fromRGB(150,150,255))
	task.wait(1)
end

local function phaseCleanup()
	broadcastPhase(Enums.Phase.Cleanup)
	TeamService.Reset()
	roundState.IsActive    = false
	roundState.CurrentPair = nil
	roundState.Winners     = "Draw"
	combatRateLimiter      = {}
	task.wait(0.5)
end

-- ════════════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════════════

function RoundService.StartLoop()
	while true do
		roundState.IsActive = false

		local ok = phaseIntermission()
		if not ok then
			task.wait(3)
			continue
		end

		roundState.IsActive    = true
		roundState.RoundNumber = roundState.RoundNumber + 1
		print(string.format("[RoundService] === Раунд %d ===", roundState.RoundNumber))

		local participants = getEligiblePlayers()
		if #participants == 0 then
			print("[RoundService] Нет участников, пропуск")
			phaseCleanup()
			continue
		end

		local pair = ChoiceService.PickNextPair()
		roundState.CurrentPair = pair
		print(string.format("[RoundService] Пара: %s vs %s", pair.LeftText, pair.RightText))

		phaseTeleportToPreArena(participants)
		phaseRevealA(pair)
		phaseRevealB(pair)
		phaseDarkChoice(pair, participants)

		local teams = phaseAssignTeams(participants)
		if not teams then
			phaseCleanup()
			continue
		end

		local allParticipants = TeamService.GetAllParticipants()

		phaseTeleportToBattle(teams)

		local winner = phaseBattle(allParticipants)
		roundState.Winners = winner

		phaseVictory(winner)
		phaseCelebration(winner, allParticipants)
		phaseReturnToLobby(allParticipants)
		phaseCleanup()
	end
end

function RoundService.GetRoundState()
	return roundState
end

return RoundService