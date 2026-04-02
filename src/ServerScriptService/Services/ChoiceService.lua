local GameConfig    = require(game.ReplicatedStorage.Config.GameConfig)
local ChoiceLibrary = require(game.ReplicatedStorage.Shared.ChoiceLibrary)

local ChoiceService = {}

local _history     = {}
local _currentPair = nil

function ChoiceService.PickNextPair()
	local pair = ChoiceLibrary.GetRandomPair(_history)
	_currentPair = pair
	table.insert(_history, pair.Id)
	if #_history > GameConfig.MAX_HISTORY_PAIRS then
		table.remove(_history, 1)
	end
	return pair
end

function ChoiceService.GetCurrentPair()
	return _currentPair
end

function ChoiceService.ClearCurrentPair()
	_currentPair = nil
end

return ChoiceService