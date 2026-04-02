local Players       = game:GetService("Players")

local LeaderboardService = {}

local _remoteCache = nil

local UPDATE_INTERVAL = 5

local function GetRemote()
	if _remoteCache then return _remoteCache end
	local folder = game.ReplicatedStorage:WaitForChild("Remotes")
	local re = folder:WaitForChild("LeaderboardUpdate")
	_remoteCache = re
	return re
end

local function CollectData()
	local data = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local wins  = ls:FindFirstChild("Wins")
			local kills = ls:FindFirstChild("Kills")
			local coins = ls:FindFirstChild("Coins")
			table.insert(data, {
				Name   = player.Name,
				UserId = player.UserId,
				Wins   = wins  and wins.Value  or 0,
				Kills  = kills and kills.Value or 0,
				Coins  = coins and coins.Value or 0,
			})
		end
	end
	table.sort(data, function(a, b)
		if a.Wins ~= b.Wins   then return a.Wins  > b.Wins  end
		if a.Kills ~= b.Kills then return a.Kills > b.Kills end
		return a.Coins > b.Coins
	end)
	return data
end

function LeaderboardService.BroadcastUpdate()
	local remote = GetRemote()
	if not remote then return end
	local data = CollectData()
	remote:FireAllClients(data)
end

function LeaderboardService.Init()
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			LeaderboardService.BroadcastUpdate()
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			LeaderboardService.BroadcastUpdate()
		end)
	end)

	Players.PlayerRemoving:Connect(function()
		task.wait(0.1)
		LeaderboardService.BroadcastUpdate()
	end)
end

return LeaderboardService