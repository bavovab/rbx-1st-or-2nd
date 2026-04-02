-- RewardService.lua
-- Grants coins for participation, winning, survival, and MVP.

local PlayerStateSvc = require(script.Parent.PlayerStateService)
local CombatService  = require(script.Parent.CombatService)
local TeamService    = require(script.Parent.TeamService)
local Enums          = require(game.ReplicatedStorage.Shared.Enums)

local RewardService = {}

local REWARDS = {
	Participation = 5,
	Winner        = 20,
	Survival      = 10,
	MVP           = 15,
}

function RewardService.GrantRoundRewards(winnerTeam, isDraw)
	local inRound = PlayerStateSvc.GetInRound()

	-- Find MVP: highest damage dealer on winning team (or all if draw)
	local mvp, mvpDamage = nil, -1

	for _, player in ipairs(inRound) do
		local state = PlayerStateSvc.Get(player)
		if state then
			-- Participation
			PlayerStateSvc.AddCoins(player, REWARDS.Participation)

			local onWinTeam = isDraw
				or (winnerTeam ~= nil and TeamService.GetTeamOf(player) == winnerTeam)

			if onWinTeam then
				PlayerStateSvc.AddWin(player)
				PlayerStateSvc.AddCoins(player, REWARDS.Winner)
			end

			if state.IsAlive then
				PlayerStateSvc.AddCoins(player, REWARDS.Survival)
			end

			-- Track MVP candidate from winning team
			if onWinTeam and state.DamageDealt > mvpDamage then
				mvpDamage = state.DamageDealt
				mvp       = player
			end
		end
	end

	-- MVP bonus
	if mvp then
		PlayerStateSvc.AddCoins(mvp, REWARDS.MVP)
	end
end

return RewardService