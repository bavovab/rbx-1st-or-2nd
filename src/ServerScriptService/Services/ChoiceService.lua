-- ModuleScript: ServerScriptService/Services/ChoiceService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChoiceLibrary = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ChoiceLibrary"))

local ChoiceService = {}

function ChoiceService.PickNextPair()
	return ChoiceLibrary.GetRandomPair()
end

return ChoiceService