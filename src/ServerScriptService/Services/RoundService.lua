-- RoundService.lua
-- Owns the central round state and runs the full round loop forever.
-- Coordinates all services and fires remotes to clients.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local Enums             = require(game.ReplicatedStorage.Shared.Enums)
local GameConfig        = require(game.ReplicatedStorage.Config.GameConfig)
local RoundConfig       = require(game.ReplicatedStorage.Config.RoundConfig)
local Utility           = require(game.ReplicatedStorage.Shared.Utility)

local PlayerStateSvc    = require(script.Parent.PlayerStateService)
local ChoiceService     = require(script.Parent.ChoiceService)
local ValidationSvc     = require(script.Parent.ValidationService)
local TeleportSvc       = require(script.Parent.TeleportServiceLocal)
local TeamService       = require(script.Parent.TeamService)
local CombatService     = require(script.Parent.CombatService)
local RewardService     = require(script.Parent.RewardService)
local CelebrationSvc    = require(script.Parent.CelebrationService)

local Remotes           = game.ReplicatedStorage.Remotes

local RoundService = {}

-- Central round state
local State = {
	Phase      = Enums.Phase.Intermission,
	RoundNumber = 0,
	CurrentPair = nil,
	WinnerTeam  = nil,
	WinnerReason = nil,
	IsDraw      = false,
	BattleActive = false,
}

-- Used to signal the battle loop to end
local _battleEnded    = false
local _battleWinner   = nil
local _battleReason   = nil

local function SetPhase(phase)
	State.Phase = phase
	local data = {
		Phase       = phase,
		RoundNumber = State.RoundNumber,
	}
	Remotes.PhaseChanged:FireAllClients(phase, data)
end

local function FireTimer(seconds)
	Remotes.TimerUpdate:FireAllClients(seconds)
end

local function CountdownPhase(duration)
	local t = duration
	while t > 0 do
		FireTimer(t)
		task.wait(1)
		t = t - 1
	end
	FireTimer(0)
end

local function GetPlayerCount()
	return #Players:GetPlayers()
end

-- ----------------------------------------------------------------
-- Battle winner callback (called from CombatService)
-- ----------------------------------------------------------------
local function OnBattleWinner(winnerTeam, reason)
	if not State.BattleActive then return end
	_battleEnded  = true
	_battleWinner = winnerTeam
	_battleReason = reason
end

-- ----------------------------------------------------------------
-- SubmitChoice handler
-- ----------------------------------------------------------------
local function OnSubmitChoice(player, side)
	local pState = PlayerStateSvc.Get(player)
	local ok, reason = ValidationSvc.ValidateSubmitChoice(player, side, State.Phase, pState)
	if not ok then return end
	PlayerStateSvc.SetChosenSide(player, side)
end

-- ----------------------------------------------------------------
-- CombatInput handler
-- ----------------------------------------------------------------
local function OnCombatInput(player, action, targetId)
	local pState = PlayerStateSvc.Get(player)
	local ok, reason = ValidationSvc.ValidateCombatInput(player, action, targetId, State.Phase, pState)
	if not ok then return end
	CombatService.ProcessInput(player, action, targetId)
end

-- ----------------------------------------------------------------
-- PlayerRemoving during round
-- ----------------------------------------------------------------
local function OnPlayerRemoving(player)
	PlayerStateSvc.OnPlayerRemoving(player)
	TeamService.RemovePlayer(player)
	ValidationSvc.CleanupPlayer(player)
	TeleportSvc.ClearSavedPosition(player)
	-- Check if this causes an early win
	if State.Phase == Enums.Phase.Battle and State.BattleActive then
		CombatService.CheckWinCondition()
	end
end

-- ----------------------------------------------------------------
-- MAIN ROUND LOOP
-- ----------------------------------------------------------------
local function RunRound()
	State.RoundNumber = State.RoundNumber + 1
	State.WinnerTeam  = nil
	State.WinnerReason = nil
	State.IsDraw      = false
	_battleEnded      = false
	_battleWinner     = nil
	_battleReason     = nil

	-- ---- INTERMISSION ----
	SetPhase(Enums.Phase.Intermission)
	local intermissionTime = RoundConfig.PHASE_DURATIONS.Intermission
	local elapsed = 0
	while elapsed < intermissionTime do
		-- Check if enough players to start
		if GetPlayerCount() >= GameConfig.MIN_PLAYERS then
			-- keep counting down
		end
		FireTimer(intermissionTime - elapsed)
		task.wait(1)
		elapsed = elapsed + 1
		-- If players drop below minimum, reset timer
		if not GameConfig.TEST_MODE and GetPlayerCount() < GameConfig.MIN_PLAYERS then
			elapsed = 0
			Remotes.HUDMessage:FireAllClients("Waiting for more players...", 2)
		end
	end
	FireTimer(0)

	-- Enroll current players into the round
	local roundPlayers = Players:GetPlayers()
	if #roundPlayers < GameConfig.MIN_PLAYERS then
		-- Not enough players, loop again
		return
	end
	PlayerStateSvc.ResetRoundState()
	for _, p in ipairs(roundPlayers) do
		PlayerStateSvc.SetInRound(p, true)
		PlayerStateSvc.SetAlive(p, true)
		TeleportSvc.SavePosition(p)
	end

	-- ---- TELEPORT TO PRE-ARENA ----
	SetPhase(Enums.Phase.TeleportToPreArena)
	TeleportSvc.TeleportToPreArena(roundPlayers)
	CountdownPhase(RoundConfig.PHASE_DURATIONS.TeleportToPreArena)

	-- ---- PICK CHOICE PAIR ----
	local pair = ChoiceService.PickNextPair()
	State.CurrentPair = pair

	-- ---- REVEAL CHOICE A ----
	SetPhase(Enums.Phase.RevealChoiceA)
	Remotes.ChoiceRevealA:FireAllClients({
		Text  = pair.LeftText,
		Color = pair.LeftColor,
		Side  = "Left",
	})
	CountdownPhase(RoundConfig.PHASE_DURATIONS.RevealChoiceA)

	-- ---- REVEAL CHOICE B ----
	SetPhase(Enums.Phase.RevealChoiceB)
	Remotes.ChoiceRevealB:FireAllClients({
		Text  = pair.RightText,
		Color = pair.RightColor,
		Side  = "Right",
	})
	CountdownPhase(RoundConfig.PHASE_DURATIONS.RevealChoiceB)

	-- ---- DARK CHOICE ----
	SetPhase(Enums.Phase.DarkChoice)
	Remotes.DarknessBegin:FireAllClients()
	-- Count down the choice timer
	local choiceTime = RoundConfig.PHASE_DURATIONS.DarkChoice
	for i = choiceTime, 1, -1 do
		FireTimer(i)
		task.wait(1)
	end
	FireTimer(0)
	Remotes.DarknessEnd:FireAllClients()

	-- ---- LOCK CHOICE ----
	SetPhase(Enums.Phase.LockChoice)
	-- Authoritative: resolve by physical zone presence if possible
	local inRoundNow = PlayerStateSvc.GetInRound()
	for _, player in ipairs(inRoundNow) do
		local pState = PlayerStateSvc.Get(player)
		-- Override UI choice with zone presence
		local zoneSide = RoundService.GetZoneSide(player)
		if zoneSide then
			PlayerStateSvc.SetChosenSide(player, zoneSide)
		end
		-- If still nil, leave as nil (TeamService will handle via config)
	end
	task.wait(RoundConfig.PHASE_DURATIONS.LockChoice)

	-- ---- ASSIGN TEAMS ----
	SetPhase(Enums.Phase.AssignTeams)
	local inRoundFinal = PlayerStateSvc.GetInRound()
	TeamService.AssignTeams(inRoundFinal)
	-- Notify each player of their team
	for _, player in ipairs(inRoundFinal) do
		local pState = PlayerStateSvc.Get(player)
		if pState and pState.InRound then
			Remotes.TeamAssigned:FireClient(player, pState.Team)
		end
	end
	task.wait(RoundConfig.PHASE_DURATIONS.AssignTeams)

	-- ---- TELEPORT TO BATTLE ----
	SetPhase(Enums.Phase.TeleportToBattle)
	local leftTeam, rightTeam = TeamService.GetBothTeams()
	TeleportSvc.TeleportTeamToBattle(leftTeam, "Left")
	TeleportSvc.TeleportTeamToBattle(rightTeam, "Right")

	-- Initialize combat
	local allInRound = PlayerStateSvc.GetInRound()
	CombatService.InitializePlayers(allInRound)
	CombatService.SetWinnerCallback(OnBattleWinner)

	-- Fire HP update to each player
	local CombatConfig = require(game.ReplicatedStorage.Config.CombatConfig)
	for _, player in ipairs(allInRound) do
		Remotes.HPUpdate:FireClient(player, CombatConfig.MAX_HP, CombatConfig.MAX_HP)
	end

	CountdownPhase(RoundConfig.PHASE_DURATIONS.TeleportToBattle)

	-- Notify teams
	for _, player in ipairs(leftTeam) do
		Remotes.BattleStart:FireClient(player, "Left", "Right")
	end
	for _, player in ipairs(rightTeam) do
		Remotes.BattleStart:FireClient(player, "Right", "Left")
	end

	-- ---- BATTLE ----
	SetPhase(Enums.Phase.Battle)
	State.BattleActive = true
	_battleEnded = false

	local battleDuration = RoundConfig.PHASE_DURATIONS.Battle
	local battleTimer    = battleDuration

	while battleTimer > 0 and not _battleEnded do
		FireTimer(battleTimer)
		task.wait(1)
		battleTimer = battleTimer - 1
	end
	FireTimer(0)

	State.BattleActive = false

	-- Resolve winner
	if _battleEnded then
		State.WinnerTeam   = _battleWinner
		State.WinnerReason = _battleReason
		State.IsDraw       = (_battleWinner == nil)
	else
		-- Timer ran out
		local winTeam, reason = CombatService.ResolveByTimer()
		State.WinnerTeam   = winTeam
		State.WinnerReason = reason
		State.IsDraw       = (winTeam == nil)
	end

	-- ---- VICTORY ----
	SetPhase(Enums.Phase.Victory)
	Remotes.VictoryAnnounced:FireAllClients(
		State.WinnerTeam or "Draw",
		State.WinnerReason or Enums.WinnerReason.Draw,
		State.IsDraw
	)
	-- Grant rewards
	RewardService.GrantRoundRewards(State.WinnerTeam, State.IsDraw)
	task.wait(RoundConfig.PHASE_DURATIONS.Victory)

	-- ---- CELEBRATION ----
	SetPhase(Enums.Phase.Celebration)
	CelebrationSvc.PlayForWinners(State.WinnerTeam, State.IsDraw)
	CountdownPhase(RoundConfig.PHASE_DURATIONS.Celebration)

	-- ---- RETURN TO LOBBY ----
	SetPhase(Enums.Phase.ReturnToLobby)
	local allPlayers = Players:GetPlayers()
	TeleportSvc.ReturnAllToLobby(allPlayers)
	task.wait(RoundConfig.PHASE_DURATIONS.ReturnToLobby)

	-- ---- CLEANUP ----
	SetPhase(Enums.Phase.Cleanup)
	CombatService.Cleanup()
	ChoiceService.ClearCurrentPair()
	PlayerStateSvc.ResetRoundState()
	TeamService.Reset()
	task.wait(RoundConfig.PHASE_DURATIONS.Cleanup)
end

-- Checks whether a player is inside the Left or Right choice zone
function RoundService.GetZoneSide(player)
	local root = Utility.GetHumanoidRootPart(player)
	if not root then return nil end
	local pos = root.Position

	local leftZone  = Utility.FindPath(workspace, {"Arena", "ChoiceLeftZone"})
	local rightZone = Utility.FindPath(workspace, {"Arena", "ChoiceRightZone"})

	local function InZone(part, point)
		if not part or not part:IsA("BasePart") then return false end
		local localPos = part.CFrame:PointToObjectSpace(point)
		local half = part.Size / 2
		return math.abs(localPos.X) <= half.X
			and math.abs(localPos.Y) <= half.Y
			and math.abs(localPos.Z) <= half.Z
	end

	if InZone(leftZone, pos) then
		return Enums.Team.Left
	elseif InZone(rightZone, pos) then
		return Enums.Team.Right
	end
	return nil
end

function RoundService.Init()
	-- Wire up remote handlers
	Remotes.SubmitChoice.OnServerEvent:Connect(OnSubmitChoice)
	Remotes.CombatInput.OnServerEvent:Connect(OnCombatInput)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	-- Start loop
	task.spawn(function()
		while true do
			local ok, err = pcall(RunRound)
			if not ok then
				warn("[RoundService] Round error:", err)
				-- Brief pause before retry to avoid tight error loop
				task.wait(5)
			end
		end
	end)
end

return RoundService