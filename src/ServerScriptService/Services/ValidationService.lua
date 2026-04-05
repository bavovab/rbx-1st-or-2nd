-- ModuleScript: ServerScriptService/Services/ValidationService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums        = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CombatConfig"))

local ValidationService = {}

local SUBMIT_CHOICE_VALID_PHASES = {
	[Enums.Phase.DarkChoice] = true,
	["DarkChoice"]           = true,
}

local COMBAT_INPUT_VALID_PHASES = {
	[Enums.Phase.Battle] = true,
	["Battle"]           = true,
}

local VALID_SIDES = {
	[Enums.Team.Left]  = true,
	[Enums.Team.Right] = true,
	["Left"]           = true,
	["Right"]          = true,
}

-- Только Melee, дэш и блок удалены
local VALID_COMBAT_ACTIONS = {
	[Enums.CombatAction.Melee] = true,
	["Melee"]                  = true,
}

function ValidationService.ValidateSubmitChoice(player, payload, roundState, allStates)
	if not player or not player.Parent then
		return false, "Player not in game"
	end

	local phase = roundState and roundState.Phase
	if not SUBMIT_CHOICE_VALID_PHASES[phase] then
		return false, "Wrong phase: " .. tostring(phase)
	end

	if type(payload) ~= "table" then
		return false, "Invalid payload type"
	end

	if not VALID_SIDES[payload.Side] then
		return false, "Invalid side: " .. tostring(payload.Side)
	end

	local state = allStates and allStates[player.UserId]
	if not state then
		return false, "No player state"
	end

	if not state.InRound then
		return false, "Player not in round"
	end

	return true, nil
end

function ValidationService.ValidateCombatInput(player, payload, roundState, allStates)
	if not player or not player.Parent then
		return false, "Player not in game"
	end

	local phase = roundState and roundState.Phase
	if not COMBAT_INPUT_VALID_PHASES[phase] then
		return false, "Wrong phase for combat: " .. tostring(phase)
	end

	if type(payload) ~= "table" then
		return false, "Invalid payload type"
	end

	if not VALID_COMBAT_ACTIONS[payload.Action] then
		return false, "Invalid action: " .. tostring(payload.Action)
	end

	local state = allStates and allStates[player.UserId]
	if not state then
		return false, "No player state"
	end

	if not state.IsAlive then
		return false, "Player is not alive"
	end

	if payload.Action == Enums.CombatAction.Melee or payload.Action == "Melee" then
		if payload.TargetId ~= nil and type(payload.TargetId) ~= "number" then
			return false, "Invalid TargetId type"
		end
	end

	return true, nil
end

return ValidationService