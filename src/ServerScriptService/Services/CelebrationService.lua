-- ModuleScript: ServerScriptService/Services/CelebrationService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ContentConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ContentConfig"))
local Enums         = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local RoundResult     = Remotes:WaitForChild("RoundResult")
local PlayCelebration = Remotes:WaitForChild("PlayCelebration")

local CelebrationService = {}

function CelebrationService.Announce(allParticipants, winnerSide, winnerPlayers, playerStateService, combatService)
	local isDraw = (winnerSide == "Draw")
	local allStates = playerStateService.GetAllStates()

	-- Умершие во время боя которые всё равно считаются победителями
	local diedInRound = combatService and combatService.GetDiedInRound() or {}

	-- Набираем ID победителей: живые победители + умершие из команды победителей
	local winnerUserIds = {}
	if not isDraw then
		for _, player in ipairs(winnerPlayers or {}) do
			winnerUserIds[player.UserId] = true
		end
		-- Добавляем умерших из winning team
		for uid, _ in pairs(diedInRound) do
			local state = allStates[uid]
			if state then
				local team = state.Team
				if team == winnerSide
					or (winnerSide == Enums.Team.Left  and (team == "Left"  or team == Enums.Team.Left))
					or (winnerSide == Enums.Team.Right and (team == "Right" or team == Enums.Team.Right)) then
					winnerUserIds[uid] = true
				end
			end
		end
	end

	local animIds = ContentConfig.ANIMATION_IDS or {}
	local celebrate1 = animIds.Celebrate1 or 0
	local celebrate2 = animIds.Celebrate2 or 0

	for _, player in ipairs(allParticipants) do
		if not player or not player.Parent then continue end

		local uid      = player.UserId
		local isWinner = isDraw or (winnerUserIds[uid] == true)

		-- Шлём результат раунда
		RoundResult:FireClient(player, {
			IsWinner   = isWinner,
			IsDraw     = isDraw,
			WinnerSide = winnerSide,
		})

		-- Победителям — анимация и звук
		if isWinner and not isDraw then
			local animId = (math.random(1, 2) == 1) and celebrate1 or celebrate2
			PlayCelebration:FireClient(player, {
				AnimId = animId,
				SfxId  = ContentConfig.SOUND_IDS and ContentConfig.SOUND_IDS.Victory or 0,
			})
		end

		print(string.format(
			"[CelebrationService] %s -> isWinner=%s isDraw=%s",
			player.Name, tostring(isWinner), tostring(isDraw)
		))
	end
end

return CelebrationService