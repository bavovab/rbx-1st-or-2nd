-- ModuleScript: ServerScriptService/Services/RewardService.lua

local RewardService = {}

local REWARDS = {
	Participation = 5,
	Winner        = 20,
	Survival      = 10,
	MVP           = 15,
}

-- allParticipants      — все игроки раунда (включая умерших)
-- winnerSide           — "Left" | "Right" | "Draw"
-- playerStateService
-- combatService        — для GetDiedInRound
-- dataService          — для сохранения Wins/Coins (опционально)
function RewardService.GrantRoundRewards(allParticipants, winnerSide, playerStateService, combatService, dataService)
	if not allParticipants or not playerStateService then
		warn("[RewardService] Invalid arguments to GrantRoundRewards")
		return
	end

	local isDraw      = (winnerSide == "Draw")
	local allStates   = playerStateService.GetAllStates()
	local diedInRound = combatService and combatService.GetDiedInRound() or {}

	local mvp, mvpDamage = nil, -1

	for _, player in ipairs(allParticipants) do
		if not player or not player.Parent then continue end

		local uid   = player.UserId
		local state = allStates[uid]
		if not state then continue end

		-- Участие — все получают
		if dataService then
			dataService.AddCoins(player, REWARDS.Participation)
		end

		-- Победа
		local teamMatches = isDraw
			or (state.Team == winnerSide)
			or (winnerSide == "Left"  and state.Team == "Left")
			or (winnerSide == "Right" and state.Team == "Right")

		local isWinner = isDraw or teamMatches

		if isWinner then
			if dataService then
				dataService.AddWin(player, 1)
				dataService.AddCoins(player, REWARDS.Winner)
			end
		end

		-- Выживание — только тот кто не умер во время боя
		if state.IsAlive and not diedInRound[uid] then
			if dataService then
				dataService.AddCoins(player, REWARDS.Survival)
			end
		end

		-- MVP кандидат — наибольший урон из победившей команды
		if isWinner and (state.DamageDealt or 0) > mvpDamage then
			mvpDamage = state.DamageDealt
			mvp       = player
		end

		print(string.format(
			"[RewardService] %s: winner=%s alive=%s damage=%d",
			player.Name,
			tostring(isWinner),
			tostring(state.IsAlive),
			state.DamageDealt or 0
		))
	end

	-- MVP бонус
	if mvp then
		if dataService then
			dataService.AddCoins(mvp, REWARDS.MVP)
		end
		print(string.format("[RewardService] MVP: %s +%d coins", mvp.Name, REWARDS.MVP))
	end

	-- Сохраняем после раздачи наград
	if dataService then
		dataService.SaveAll()
	end
end

return RewardService