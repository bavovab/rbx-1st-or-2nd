-- ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Config     = ReplicatedStorage:WaitForChild("Config")
local Enums      = require(Shared:WaitForChild("Enums"))
local GameConfig = require(Config:WaitForChild("GameConfig"))

local TeamService = {}

local teamAssignments = { Left = {}, Right = {} }

function TeamService.Reset()
	teamAssignments = { Left = {}, Right = {} }
end

function TeamService.AssignTeams(players, playerStates)
	TeamService.Reset()
	local undecided = {}

	for _, player in ipairs(players) do
		local ps = playerStates[player.UserId]
		if not ps then continue end
		local side = ps.SelectedSide
		if side == Enums.Team.Left then
			table.insert(teamAssignments.Left, player)
		elseif side == Enums.Team.Right then
			table.insert(teamAssignments.Right, player)
		else
			table.insert(undecided, player)
		end
	end

	-- Handle undecided players
	local mode = GameConfig.UNDECIDED_MODE or "RandomAssign"
	if GameConfig.AUTO_ASSIGN_UNDECIDED and mode == "RandomAssign" then
		for _, player in ipairs(undecided) do
			if #teamAssignments.Left <= #teamAssignments.Right then
				table.insert(teamAssignments.Left, player)
			else
				table.insert(teamAssignments.Right, player)
			end
		end
	end

	return teamAssignments
end

function TeamService.GetTeams()
	return teamAssignments
end

function TeamService.GetTeam(side)
	return teamAssignments[side] or {}
end

function TeamService.GetAliveCount(side, playerStates)
	local count = 0
	for _, player in ipairs(teamAssignments[side] or {}) do
		local ps = playerStates[player.UserId]
		if ps and ps.IsAlive then count = count + 1 end
	end
	return count
end

function TeamService.GetTotalHP(side, playerStates)
	local total = 0
	for _, player in ipairs(teamAssignments[side] or {}) do
		local ps = playerStates[player.UserId]
		if ps and ps.IsAlive then total = total + ps.HP end
	end
	return total
end

function TeamService.IsTeamWiped(side, playerStates)
	return TeamService.GetAliveCount(side, playerStates) == 0
end

function TeamService.ResolveWinner(playerStates, resolveOrder)
	local leftAlive  = TeamService.GetAliveCount("Left",  playerStates)
	local rightAlive = TeamService.GetAliveCount("Right", playerStates)
	local leftHP     = TeamService.GetTotalHP("Left",  playerStates)
	local rightHP    = TeamService.GetTotalHP("Right", playerStates)

	for _, method in ipairs(resolveOrder) do
		if method == "AliveCount" then
			if leftAlive > rightAlive then return "Left"
			elseif rightAlive > leftAlive then return "Right" end
		elseif method == "TotalHP" then
			if leftHP > rightHP then return "Left"
			elseif rightHP > leftHP then return "Right" end
		elseif method == "Draw" then
			return "Draw"
		end
	end
	return "Draw"
end

function TeamService.GetAllParticipants()
	local all = {}
	for _, p in ipairs(teamAssignments.Left)  do table.insert(all, p) end
	for _, p in ipairs(teamAssignments.Right) do table.insert(all, p) end
	return all
end

return TeamService