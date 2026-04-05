-- ModuleScript: ServerScriptService/Services/TeamService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

local TeamService = {}

local currentTeams = {
	Left = {},
	Right = {},
}

local function clearTeams()
	currentTeams.Left = {}
	currentTeams.Right = {}
end

function TeamService.AssignTeams(participants, allStates)
	clearTeams()

	for _, player in ipairs(participants) do
		local state = allStates[player.UserId]
		local selectedSide = state and state.SelectedSide or nil

		if selectedSide == Enums.Team.Left or selectedSide == "Left" then
			table.insert(currentTeams.Left, player)
		elseif selectedSide == Enums.Team.Right or selectedSide == "Right" then
			table.insert(currentTeams.Right, player)
		else
			print(string.format("[TeamService] %s has no valid selected side; leaving unassigned.", player.Name))
		end
	end

	print(string.format(
		"[TeamService] Assigned strictly by player choice. Left=%d, Right=%d",
		#currentTeams.Left,
		#currentTeams.Right
	))

	return currentTeams
end

function TeamService.GetTeam(side)
	if side == Enums.Team.Left or side == "Left" then
		return currentTeams.Left
	elseif side == Enums.Team.Right or side == "Right" then
		return currentTeams.Right
	end
	return {}
end

function TeamService.GetAllParticipants()
	local result = {}

	for _, player in ipairs(currentTeams.Left) do
		table.insert(result, player)
	end

	for _, player in ipairs(currentTeams.Right) do
		table.insert(result, player)
	end

	return result
end

function TeamService.ResolveWinner(allStates, resolveOrder)
	resolveOrder = resolveOrder or { "AliveCount", "TotalHP", "Draw" }

	local leftAlive, rightAlive = 0, 0
	local leftHP, rightHP = 0, 0

	for _, player in ipairs(currentTeams.Left) do
		local state = allStates[player.UserId]
		if state then
			if state.IsAlive then
				leftAlive += 1
			end
			leftHP += math.max(0, state.HP or 0)
		end
	end

	for _, player in ipairs(currentTeams.Right) do
		local state = allStates[player.UserId]
		if state then
			if state.IsAlive then
				rightAlive += 1
			end
			rightHP += math.max(0, state.HP or 0)
		end
	end

	for _, method in ipairs(resolveOrder) do
		if method == "AliveCount" then
			if leftAlive > rightAlive then
				return Enums.Team.Left
			elseif rightAlive > leftAlive then
				return Enums.Team.Right
			end
		elseif method == "TotalHP" then
			if leftHP > rightHP then
				return Enums.Team.Left
			elseif rightHP > leftHP then
				return Enums.Team.Right
			end
		elseif method == "Draw" then
			return "Draw"
		end
	end

	return "Draw"
end

function TeamService.Reset()
	clearTeams()
	print("[TeamService] Reset.")
end

return TeamService