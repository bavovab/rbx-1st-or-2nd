-- ValidationService.lua
-- Validates all incoming RemoteEvent payloads server-side.

local Enums      = require(game.ReplicatedStorage.Shared.Enums)
local GameConfig = require(game.ReplicatedStorage.Config.GameConfig)
local CombatConfig = require(game.ReplicatedStorage.Config.CombatConfig)

local ValidationService = {}

-- Per-player cooldown timestamps for combat actions
local _attackCooldowns = {}
local _dashCooldowns   = {}
local _blockCooldowns  = {}

-- Per-player last SubmitChoice timestamp
local _choiceCooldowns = {}

local CHOICE_COOLDOWN = 0.5  -- prevent spam

function ValidationService.CleanupPlayer(player)
	local id = player.UserId
	_attackCooldowns[id] = nil
	_dashCooldowns[id]   = nil
	_blockCooldowns[id]  = nil
	_choiceCooldowns[id] = nil
end

-- Returns ok (bool), reason (string|nil)
function ValidationService.ValidateSubmitChoice(player, side, currentPhase, playerState)
	if currentPhase ~= Enums.Phase.DarkChoice then
		return false, "Wrong phase"
	end
	if side ~= Enums.Team.Left and side ~= Enums.Team.Right then
		return false, "Invalid side"
	end
	if not playerState or not playerState.InRound then
		return false, "Player not in round"
	end
	local now = os.clock()
	local id  = player.UserId
	if _choiceCooldowns[id] and (now - _choiceCooldowns[id]) < CHOICE_COOLDOWN then
		return false, "Cooldown"
	end
	_choiceCooldowns[id] = now
	return true, nil
end

-- Returns ok (bool), reason (string|nil)
function ValidationService.ValidateCombatInput(player, action, targetId, currentPhase, playerState)
	if currentPhase ~= Enums.Phase.Battle then
		return false, "Wrong phase"
	end
	if not playerState or not playerState.InRound or not playerState.IsAlive then
		return false, "Player not alive in round"
	end
	if action ~= Enums.CombatAction.Attack
		and action ~= Enums.CombatAction.Dash
		and action ~= Enums.CombatAction.Block then
		return false, "Invalid action"
	end
	if action == Enums.CombatAction.Attack and targetId ~= nil then
		if type(targetId) ~= "number" then
			return false, "Bad targetId type"
		end
	end
	local now = os.clock()
	local id  = player.UserId
	if action == Enums.CombatAction.Attack then
		if _attackCooldowns[id] and (now - _attackCooldowns[id]) < CombatConfig.ATTACK_COOLDOWN then
			return false, "Attack cooldown"
		end
		_attackCooldowns[id] = now
	elseif action == Enums.CombatAction.Dash then
		if _dashCooldowns[id] and (now - _dashCooldowns[id]) < CombatConfig.DASH_COOLDOWN then
			return false, "Dash cooldown"
		end
		_dashCooldowns[id] = now
	elseif action == Enums.CombatAction.Block then
		if _blockCooldowns[id] and (now - _blockCooldowns[id]) < CombatConfig.BLOCK_COOLDOWN then
			return false, "Block cooldown"
		end
		_blockCooldowns[id] = now
	end
	return true, nil
end

return ValidationService