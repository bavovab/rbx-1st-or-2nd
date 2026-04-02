local Players  = game:GetService("Players")
local UIConfig = require(game.ReplicatedStorage.Config.UIConfig)
local Enums    = require(game.ReplicatedStorage.Shared.Enums)

local HUDController = require(script.Parent.HUDController)

local LocalPlayer = Players.LocalPlayer

local CelebrationController = {}

local _myTeam = nil

-- Called when TeamAssigned fires — store local player's team
function CelebrationController.SetMyTeam(team)
	_myTeam = team
end

function CelebrationController.OnVictoryAnnounced(winnerTeam, reason)
	if _myTeam == nil then
		HUDController.ShowResult("Round Over!", "Result: " .. tostring(winnerTeam), UIConfig.TEXT_PRIMARY)
		return
	end

	if winnerTeam == _myTeam then
		HUDController.ShowResult("VICTORY!", "Your team won! (" .. tostring(reason) .. ")", UIConfig.WIN_COLOR)
	else
		HUDController.ShowResult("DEFEAT", "Better luck next round.", UIConfig.LOSE_COLOR)
	end
end

function CelebrationController.OnCelebrationStart(winnerTeam)
	if winnerTeam == "Draw" then
		HUDController.ShowResult("DRAW!", "Both teams fought well.", UIConfig.DRAW_COLOR)
		return
	end

	if _myTeam == winnerTeam then
		HUDController.ShowBanner("🎉 YOUR TEAM WINS!", UIConfig.WIN_COLOR, 0)
	else
		HUDController.ShowBanner("You lost this round.", UIConfig.LOSE_COLOR, 0)
	end
end

function CelebrationController.Init()
	-- Hook TeamAssigned to track local player's team
	local RemotesFolder  = game.ReplicatedStorage:WaitForChild("Remotes")
	local RemoteTeamAssigned = RemotesFolder:WaitForChild("TeamAssigned")
	RemoteTeamAssigned.OnClientEvent:Connect(function(teamName)
		_myTeam = teamName
	end)
end

return CelebrationController