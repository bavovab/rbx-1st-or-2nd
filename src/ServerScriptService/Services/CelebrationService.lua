-- CelebrationService.lua
-- Triggers winner-only celebration animations and victory sound on clients.

local ContentConfig = require(game.ReplicatedStorage.Config.ContentConfig)
local Remotes       = game.ReplicatedStorage.Remotes
local TeamService   = require(script.Parent.TeamService)
local Enums         = require(game.ReplicatedStorage.Shared.Enums)

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

	-- Fire CelebrationStart to ALL clients so losers see the result panel too
	-- The winnerTeam string is used by each client to know if they won
	Remotes.CelebrationStart:FireAllClients(winnerTeam or "Draw")

	-- Per-winner: trigger celebration anim server-side via Humanoid
	for _, player in ipairs(winners) do
		task.spawn(function()
			local char = player.Character
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			-- Play animation if asset ID is set
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