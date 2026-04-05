-- ModuleScript: ServerScriptService/Services/RewardService.lua

local RewardService = {}

local REWARDS = {
	Participation = 5,
	Winner        = 20,
	Survival      = 10,
	MVP           = 15,
}

-- allParticipants  — все игроки раунда (включая умерших во время боя)
-- winnerSide       — "Left" | "Right" | "Draw"
-- playerStateService
-- combatService    — для получения diedInRound
function RewardService.GrantRoundRewards(allParticipants, winnerSide, playerStateService, combatService)
	if not allParticipants or not playerStateService then
		warn("[RewardService] Invalid arguments to GrantRoundRewards")
		return
	end

	local isDraw    = (winnerSide == "Draw")
	local allStates = playerStateService.GetAllStates()
	local diedInRound = combatService and combatService.GetDiedInRound() or {}

	local mvp, mvpDamage = nil, -1

	for _, player in ipairs(allParticipants) do
		if not player or not player.Parent then continue end

		local uid   = player.UserId
		local state = allStates[uid]
		if not state then continue end

		local ls = player:FindFirstChild("leaderstats")
		if not ls then continue end

		local coinsVal = ls:FindFirstChild("Coins")
		local winsVal  = ls:FindFirstChild("Wins")

		-- Участие — все получают
		if coinsVal then coinsVal.Value += REWARDS.Participation end

		-- Победа: живые победители + умершие из winning team
		local teamMatches = isDraw
			or (state.Team == winnerSide)
			or (winnerSide == "Left"  and state.Team == "Left")
			or (winnerSide == "Right" and state.Team == "Right")

		local isWinner = isDraw or teamMatches

		if isWinner then
			if winsVal  then winsVal.Value  += 1 end
			if coinsVal then coinsVal.Value += REWARDS.Winner end
		end

		-- Выживание — только тот, кто не умер во время боя
		if state.IsAlive and not diedInRound[uid] then
			if coinsVal then coinsVal.Value += REWARDS.Survival end
		end

		-- MVP кандидат — наибольший урон из победившей команды
		if isWinner and (state.DamageDealt or 0) > mvpDamage then
			mvpDamage = state.DamageDealt
			mvp = player
		end

		print(string.format(
			"[RewardService] %s: winner=%s, alive=%s, damage=%d",
			player.Name,
			tostring(isWinner),
			tostring(state.IsAlive),
			state.DamageDealt or 0
		))
	end

	-- MVP бонус
	if mvp then
		local ls = mvp:FindFirstChild("leaderstats")
		if ls then
			local coinsVal = ls:FindFirstChild("Coins")
			if coinsVal then coinsVal.Value += REWARDS.MVP end
			print(string.format("[RewardService] MVP: %s +%d coins", mvp.Name, REWARDS.MVP))
		end
	end
end

return RewardService