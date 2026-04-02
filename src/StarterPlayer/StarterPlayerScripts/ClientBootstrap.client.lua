local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Wait for remotes to exist before initialising controllers
local RemotesFolder = game.ReplicatedStorage:WaitForChild("Remotes")

local HUDController         = require(script.Parent.Controllers.HUDController)
local ChoiceController      = require(script.Parent.Controllers.ChoiceController)
local DarknessController    = require(script.Parent.Controllers.DarknessController)
local CombatController      = require(script.Parent.Controllers.CombatController)
local CelebrationController = require(script.Parent.Controllers.CelebrationController)

local Enums    = require(game.ReplicatedStorage.Shared.Enums)
local UIConfig = require(game.ReplicatedStorage.Config.UIConfig)

-- Remote references
local RemotePhaseChanged     = RemotesFolder:WaitForChild("PhaseChanged")
local RemoteTimerUpdate      = RemotesFolder:WaitForChild("TimerUpdate")
local RemoteChoiceRevealA    = RemotesFolder:WaitForChild("ChoiceRevealA")
local RemoteChoiceRevealB    = RemotesFolder:WaitForChild("ChoiceRevealB")
local RemoteDarknessBegin    = RemotesFolder:WaitForChild("DarknessBegin")
local RemoteDarknessEnd      = RemotesFolder:WaitForChild("DarknessEnd")
local RemoteTeamAssigned     = RemotesFolder:WaitForChild("TeamAssigned")
local RemoteBattleStart      = RemotesFolder:WaitForChild("BattleStart")
local RemotePlayerEliminated = RemotesFolder:WaitForChild("PlayerEliminated")
local RemoteVictoryAnnounced = RemotesFolder:WaitForChild("VictoryAnnounced")
local RemoteCelebrationStart = RemotesFolder:WaitForChild("CelebrationStart")
local RemoteHUDMessage       = RemotesFolder:WaitForChild("HUDMessage")
local RemoteHPUpdate         = RemotesFolder:WaitForChild("HPUpdate")

-- Initialise all controllers
HUDController.Build()
ChoiceController.Init()
DarknessController.Init()
CombatController.Init()
CelebrationController.Init()

-- Phase changed
RemotePhaseChanged.OnClientEvent:Connect(function(phase, data)
	local label = UIConfig.LABELS[phase] or phase
	HUDController.SetStatus(label)
	HUDController.HideBanner()
	HUDController.HideResult()

	if phase == Enums.Phase.Intermission then
		ChoiceController.HideCards()
		HUDController.HideHP()
		CombatController.SetActive(false)

	elseif phase == Enums.Phase.TeleportToPreArena then
		ChoiceController.HideCards()
		HUDController.ShowBanner("Heading to the arena!", nil, 3)

	elseif phase == Enums.Phase.RevealChoiceA then
		-- ChoiceRevealA remote handles the card display

	elseif phase == Enums.Phase.RevealChoiceB then
		-- ChoiceRevealB remote handles the card display

	elseif phase == Enums.Phase.DarkChoice then
		ChoiceController.OpenChoice()
		HUDController.ShowBanner("Choose your side!", Color3.fromRGB(255, 220, 50), 0)

	elseif phase == Enums.Phase.LockChoice then
		ChoiceController.CloseChoice()
		HUDController.ShowBanner("Choices locked!", nil, 2)

	elseif phase == Enums.Phase.AssignTeams then
		HUDController.ShowBanner("Assigning teams...", nil, 2)

	elseif phase == Enums.Phase.TeleportToBattle then
		ChoiceController.HideCards()
		HUDController.ShowBanner("Battle begins!", Color3.fromRGB(255, 80, 80), 3)

	elseif phase == Enums.Phase.Battle then
		HUDController.ShowBanner("FIGHT!", Color3.fromRGB(255, 50, 50), 2)
		CombatController.SetActive(true)

	elseif phase == Enums.Phase.Victory then
		CombatController.SetActive(false)
		HUDController.HideHP()

	elseif phase == Enums.Phase.ReturnToLobby then
		HUDController.ShowBanner("Returning to lobby...", nil, 3)
		CombatController.SetActive(false)

	elseif phase == Enums.Phase.Cleanup then
		HUDController.HideBanner()
		HUDController.HideResult()
		HUDController.ClearTimer()
	end
end)

-- Timer
RemoteTimerUpdate.OnClientEvent:Connect(function(seconds)
	HUDController.SetTimer(seconds)
end)

-- Choice reveal A
RemoteChoiceRevealA.OnClientEvent:Connect(function(data)
	ChoiceController.RevealCard("Left", data)
end)

-- Choice reveal B
RemoteChoiceRevealB.OnClientEvent:Connect(function(data)
	ChoiceController.RevealCard("Right", data)
end)

-- 