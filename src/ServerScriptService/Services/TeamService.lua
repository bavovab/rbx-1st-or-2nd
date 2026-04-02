-- TeamService.lua
-- Assigns players to Left/Right teams and exposes team query functions.

local Enums              = require(game.ReplicatedStorage.Shared.Enums)
local GameConfig         = require(game.ReplicatedStorage.Config.GameConfig)
local Utility            = require(game.ReplicatedStorage.Shared.Utility)
local PlayerStateService = require(script.Parent.PlayerStateService)
local TeleportSvc        = require(script.Parent.TeleportServiceLocal)

local TeamService = {}

-- _teams[Enums.Team.Left|Right] = { player, ... }
local _teams = {
	[Enums.Team.Left]  = {},
	[Enums.Team.Right] = {},
}

function TeamService.Reset()
	_teams[Enums.Team.Left]  = {}
	_teams[Enums.Team.Right] = {}
end

-- Build teams from player chosen sides, handle undecided players per config.
function TeamService.AssignTeams(inRoundPlayers)
	TeamService.Reset()

	local undecided = {}

	for _, player in ipairs(inRoundPlayers) do
		local state = PlayerStateService.Get(player)
		if state then
			local side = state.ChosenSide
			if side == Enums.Team.Left then
				table.insert(_teams[Enums.Team.Left], player)
				PlayerStateService.SetTeam(player, Enums.Team.Left)
			elseif side == Enums.Team.Right then
				table.insert(_teams[Enums.Team.Right], player)
				PlayerStateService.SetTeam(player, Enums.Team.Right)
			else
				table.insert(undecided, player)
			end
		end
	end

	-- Handle undecided players
	if GameConfig.AUTO_ASSIGN_UNDECIDED then
		local mode = GameConfig.UNDECIDED_MODE
		for _, player in ipairs(undecided) do
			if mode == Enums.UndecidedMode.Eliminate then
				PlayerStateService.SetInRound(player, false)
				TeleportSvc.ReturnPlayerToLobby(player)
			elseif mode == Enums.UndecidedMode.Smaller then
				local leftCount  = #_teams[Enums.Team.Left]
				local rightCount = #_teams[Enums.Team.Right]
				local side = (leftCount <= rightCount) and Enums.Team.Left or Enums.Team.Right
				table.insert(_teams[side], player)
				PlayerStateService.SetTeam(player, side)
			else
				-- Random
				local side = (math.random(1, 2) == 1) and Enums.Team.Left or Enums.Team.Right
				table.insert(_teams[side], player)
				PlayerStateService.SetTeam(player, side)
			end
		end
	else
		-- If not auto-assigning, undecided are removed from round
		for _, player in ipairs(undecided) do
			PlayerStateService.SetInRound(player, false)
			TeleportSvc.ReturnPlayerToLobby(player)
		end
	end
end

function TeamService.GetTeam(side)
	return Utility.ShallowCopy(_teams[side] or {})
end

function TeamService.GetBothTeams()
	return Utility.ShallowCopy(_teams[Enums.Team.Left]),
	       Utility.ShallowCopy(_teams[Enums.Team.Right])
end

function TeamService.GetTeamOf(player)
	for _, side in ipairs({Enums.Team.Left, Enums.Team.Right}) do
		for _, p in ipairs(_teams[side]) do
			if p == player then return side end
		end
	end
	return Enums.Team.None
end

function TeamService.GetAliveCount(side)
	local count = 0
	for _, player in ipairs(_teams[side]) do
		local state = PlayerStateService.Get(player)
		if state and state.IsAlive then
			count = count + 1
		end
	end
	return count
end

-- Remove player from whichever team they are on (e.g. on disconnect mid-round)
function TeamService.RemovePlayer(player)
	for _, side in ipairs({Enums.Team.Left, Enums.Team.Right}) do
		Utility.RemoveValue(_teams[side], player)
	end
end

return TeamService