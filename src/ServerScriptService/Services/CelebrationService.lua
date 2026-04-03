-- ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentConfig     = require(ReplicatedStorage.Config.ContentConfig)

local CelebrationService = {}

-- Use WaitForChild with timeout to avoid infinite yield
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local RoundResult     = Remotes and Remotes:WaitForChild("RoundResult",     10)
local PlayCelebration = Remotes and Remotes:WaitForChild("PlayCelebration", 10)

function CelebrationService.Announce(allPlayers, winnerSide, winnerPlayers, playerStates)
	if not RoundResult or not PlayCelebration then
		warn("[CelebrationService] Remotes not found, skipping announce.")
		return
	end

	local allStates = playerStates.GetAllStates()

	for _, player in ipairs(allPlayers) do
		if not player or not player.Parent then continue end
		local ps = allStates[player.UserId]
		if not ps then continue end

		local isWinner = (winnerSide ~= "Draw") and (ps.Team == winnerSide)
		local isDraw   = (winnerSide == "Draw")

		-- Send result UI to everyone
		RoundResult:FireClient(player, {
			IsWinner   = isWinner,
			IsDraw     = isDraw,
			WinnerSide = winnerSide,
		})

		-- Send celebration only to winners
		if isWinner then
			PlayCelebration:FireClient(player, {
				AnimId = ContentConfig.ANIMATION_IDS.Celebrate1,
				SfxId  = ContentConfig.SOUND_IDS.WinSting,
			})
		end
	end
end

return CelebrationService