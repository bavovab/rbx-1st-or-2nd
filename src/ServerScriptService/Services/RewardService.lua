-- ModuleScript
local RewardService = {}

local REWARDS = {
	Participation = 5,
	Winner        = 20,
	Survival      = 10,
	MVP           = 15,
}

-- Инжектируется через RoundService: GrantRoundRewards(allParticipants, winner, PlayerStateService)
function RewardService.GrantRoundRewards(allParticipants, winnerSide, playerStateService)
	if not allParticipants or not playerStateService then
		warn("[RewardService] Неверные аргументы GrantRoundRewards")
		return
	end

	local allStates = playerStateService.GetAllStates()
	local isDraw    = (winnerSide == "Draw")

	local mvp, mvpDamage = nil, -1

	for _, player in ipairs(allParticipants) do
		if not player or not player.Parent then continue end
		local ps = allStates[player.UserId]
		if not ps then continue end

		-- Участие
		local ls = player:FindFirstChild("leaderstats")
		if not ls then continue end

		local coinsVal = ls:FindFirstChild("Coins")
		local winsVal  = ls:FindFirstChild("Wins")

		if coinsVal then
			coinsVal.Value = coinsVal.Value + REWARDS.Participation
		end

		local onWinTeam = isDraw or (winnerSide ~= nil and ps.Team == winnerSide)

		if onWinTeam then
			if winsVal  then winsVal.Value  = winsVal.Value  + 1 end
			if coinsVal then coinsVal.Value = coinsVal.Value + REWARDS.Winner end
		end

		if ps.IsAlive then
			if coinsVal then coinsVal.Value = coinsVal.Value + REWARDS.Survival end
		end

		-- MVP кандидат с победившей команды
		if onWinTeam and ps.DamageDealt > mvpDamage then
			mvpDamage = ps.DamageDealt
			mvp       = player
		end

		print(string.format("[RewardService] %s: +%d coins, win=%s, alive=%s",
			player.Name,
			REWARDS.Participation + (onWinTeam and REWARDS.Winner or 0) + (ps.IsAlive and REWARDS.Survival or 0),
			tostring(onWinTeam),
			tostring(ps.IsAlive)
		))
	end

	-- MVP бонус
	if mvp then
		local ls = mvp:FindFirstChild("leaderstats")
		if ls then
			local coinsVal = ls:FindFirstChild("Coins")
			if coinsVal then coinsVal.Value = coinsVal.Value + REWARDS.MVP end
			print(string.format("[RewardService] MVP: %s +%d coins", mvp.Name, REWARDS.MVP))
		end
	end
end

return RewardService