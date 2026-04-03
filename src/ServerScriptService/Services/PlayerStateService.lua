-- ModuleScript
local Players = game:GetService("Players")

local PlayerStateService = {}

local playerStates = {}

local function defaultState()
	return {
		InRound      = false,
		IsAlive      = false,
		Team         = "None",
		SelectedSide = nil,
		HP           = 0,
		Kills        = 0,
		DamageDealt  = 0,
		SavedCFrame  = nil,
	}
end

local function createLeaderstats(player)
	if player:FindFirstChild("leaderstats") then return end

	local ls = Instance.new("Folder")
	ls.Name   = "leaderstats"
	ls.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name   = "Wins"
	wins.Value  = 0
	wins.Parent = ls

	local kills = Instance.new("IntValue")
	kills.Name   = "Kills"
	kills.Value  = 0
	kills.Parent = ls

	local coins = Instance.new("IntValue")
	coins.Name   = "Coins"
	coins.Value  = 0
	coins.Parent = ls
end

function PlayerStateService.Init()
	Players.PlayerAdded:Connect(function(player)
		playerStates[player.UserId] = defaultState()
		createLeaderstats(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerStates[player.UserId] = nil
	end)

	-- Init players already in server
	for _, player in ipairs(Players:GetPlayers()) do
		if not playerStates[player.UserId] then
			playerStates[player.UserId] = defaultState()
			createLeaderstats(player)
		end
	end

	print("[PlayerStateService] Initialized.")
end

function PlayerStateService.GetState(player)
	return playerStates[player.UserId]
end

function PlayerStateService.GetAllStates()
	return playerStates
end

function PlayerStateService.SetInRound(player, val)
	local ps = playerStates[player.UserId]
	if ps then ps.InRound = val end
end

function PlayerStateService.SetTeam(player, team)
	local ps = playerStates[player.UserId]
	if ps then ps.Team = team end
end

function PlayerStateService.SetSelectedSide(player, side)
	local ps = playerStates[player.UserId]
	if ps then ps.SelectedSide = side end
end

function PlayerStateService.SetAlive(player, val)
	local ps = playerStates[player.UserId]
	if ps then ps.IsAlive = val end
end

function PlayerStateService.SetHP(player, hp)
	local ps = playerStates[player.UserId]
	if ps then ps.HP = hp end
end

function PlayerStateService.SavePosition(player)
	local ps = playerStates[player.UserId]
	if not ps then return end
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			ps.SavedCFrame = hrp.CFrame
		end
	end
end

function PlayerStateService.GetSavedCFrame(player)
	local ps = playerStates[player.UserId]
	if ps then return ps.SavedCFrame end
	return nil
end

function PlayerStateService.ResetForRound(player)
	local ps = playerStates[player.UserId]
	if ps then
		ps.InRound      = false
		ps.IsAlive      = false
		ps.Team         = "None"
		ps.SelectedSide = nil
		ps.HP           = 0
		ps.Kills        = 0
		ps.DamageDealt  = 0
	end
end

function PlayerStateService.AddKill(player)
	local ps = playerStates[player.UserId]
	if ps then ps.Kills = ps.Kills + 1 end
end

function PlayerStateService.AddDamage(player, amount)
	local ps = playerStates[player.UserId]
	if ps then ps.DamageDealt = ps.DamageDealt + amount end
end

function PlayerStateService.CreateLeaderstats(player)
	createLeaderstats(player)
end

return PlayerStateService