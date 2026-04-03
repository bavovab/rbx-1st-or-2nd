-- ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChoiceLibrary = require(ReplicatedStorage.Shared.ChoiceLibrary)
local GameConfig    = require(ReplicatedStorage.Config.GameConfig)

local ChoiceService = {}

-- Возвращает пару { Left = option, Right = option, LeftText, RightText, ... }
function ChoiceService.PickNextPair()
	return ChoiceLibrary.GetRandomPair(GameConfig.MAX_HISTORY_PAIRS)
end

function ChoiceService.ResetHistory()
	ChoiceLibrary.ResetHistory()
end

return ChoiceService