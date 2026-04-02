local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RemotesFolder = game.ReplicatedStorage:WaitForChild("Remotes")

local HUDController          = require(script.Parent.Controllers.HUDController)
local ChoiceController       = require(script.Parent.Controllers.ChoiceController)
local DarknessController     = require(script.Parent.Controllers.DarknessController)
local CombatController       = require(script.Parent.Controllers.CombatController)
local CelebrationController  = require(script.Parent.Controllers.CelebrationController)
local LeaderboardController  = require(script.Parent.Controllers.LeaderboardController)

local Enums    = require(game.ReplicatedStorage.Shared.Enums)
local UIConfig = require(game.ReplicatedStorage.Config.UIConfig)

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

-- Инициализация
HUDController.Build()
ChoiceController.Init()
DarknessController.Init()
CombatController.Init()
CelebrationController.Init()
LeaderboardController.Init()

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

RemoteTimerUpdate.OnClientEvent:Connect(function(seconds)
	HUDController.SetTimer(seconds)
end)

RemoteChoiceRevealA.OnClientEvent:Connect(function(data)
	ChoiceController.RevealCard("Left", data)
end)

RemoteChoiceRevealB.OnClientEvent:Connect(function(data)
	ChoiceController.RevealCard("Right", data)
end)

RemoteDarknessBegin.OnClientEvent:Connect(function()
	DarknessController.Begin()
end)

RemoteDarknessEnd.OnClientEvent:Connect(function()
	DarknessController.End()
end)

RemoteTeamAssigned.OnClientEvent:Connect(function(teamName)
	local color
	if teamName == Enums.Team.Left then
		color = UIConfig.LEFT_COLOR_DEFAULT
	elseif teamName == Enums.Team.Right then
		color = UIConfig.RIGHT_COLOR_DEFAULT
	else
		color = UIConfig.TEXT_PRIMARY
	end
	HUDController.ShowBanner("You are: " .. tostring(teamName), color, 4)
	CelebrationController.SetMyTeam(teamName)
end)

RemoteBattleStart.OnClientEvent:Connect(function(myTeam, enemyTeam)
	HUDController.ShowBanner("FIGHT! [" .. myTeam .. "] vs [" .. enemyTeam .. "]", Color3.fromRGB(255, 60, 60), 3)
end)

RemotePlayerEliminated.OnClientEvent:Connect(function(playerName)
	HUDController.ShowMessage(playerName .. " was eliminated!", 2)
end)

RemoteVictoryAnnounced.OnClientEvent:Connect(function(winnerTeam, reason, isDraw)
	if isDraw then
		HUDController.ShowResult("DRAW!", "Both teams fought well.", UIConfig.DRAW_COLOR)
	else
		CelebrationController.OnVictoryAnnounced(winnerTeam, reason)
	end
end)

RemoteCelebrationStart.OnClientEvent:Connect(function(winnerTeam)
	CelebrationController.OnCelebrationStart(winnerTeam)
end)

RemoteHUDMessage.OnClientEvent:Connect(function(message, duration)
	HUDController.ShowMessage(message, duration)
end)

RemoteHPUpdate.OnClientEvent:Connect(function(current, max)
	HUDController.ShowHP(current, max)
end)

print("[ClientBootstrap] PartyPvP client started.")