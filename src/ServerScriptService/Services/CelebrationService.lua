local ContentConfig = require(game.ReplicatedStorage.Config.ContentConfig)
local TeamService   = require(script.Parent.TeamService)
local Enums         = require(game.ReplicatedStorage.Shared.Enums)

local RemotesFolder      = game.ReplicatedStorage:WaitForChild("Remotes")
local RemoteCelebration  = RemotesFolder:WaitForChild("CelebrationStart")

local CelebrationService = {}

function CelebrationService.PlayForWinners(winnerTeam, isDraw)
	local winners = {}
	if isDraw then
		local left, right = TeamService.GetBothTeams()
		for _, p in ipairs(left)  do table.insert(winners, p) end
		for _, p in ipairs(right) do table.insert(winners, p) end
	elseif winnerTeam then
		winners = TeamService.GetTeam(winnerTeam)
	end

	RemoteCelebration:FireAllClients(winnerTeam or "Draw")

	for _, player in ipairs(winners) do
		task.spawn(function()
			local char = player.Character
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			local animId = ContentConfig.Animations.CelebrationWin
			if animId and animId ~= 0 then
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. tostring(animId)
				local track = hum:LoadAnimation(anim)
				track:Play()
			end
		end)
	end
end

return CelebrationService