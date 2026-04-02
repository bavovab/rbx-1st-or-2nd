local Enums = require(game.ReplicatedStorage.Shared.Enums)
local PlayerStateService = {}
local _state = {}

local function createLeaderstats(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	local w = Instance.new("IntValue")
	w.Name = "Wins"
	w.Parent = ls
	local c = Instance.new("IntValue")
	c.Name = "Coins"
	c.Parent = ls
	local k = Instance.new("IntValue")
	k.Name = "Kills"
	k.Parent = ls
end

function PlayerStateService.OnPlayerAdded(player)
	_state[player] = {
		InRound = false,
		IsAlive = false,
		Team = Enums.Team.None,
		ChosenSide = nil,
		Kills = 0,
		DamageDealt = 0,
		Wins = 0,
		Coins = 0,
	}
	createLeaderstats(player)
end

function PlayerStateService.OnPlayerRemoving(player)
	_state[player] = nil
end

function PlayerStateService.Get(player)
	return _state[player]
end

function PlayerStateService.SetInRound(player, v)
	if _state[player] then
		_state[player].InRound = v
		if not v then
			_state[player].IsAlive = false
			_state[player].Team = Enums.Team.None
			_state[player].ChosenSide = nil
		end
	end
end

function PlayerStateService.SetAlive(player, v)
	if _state[player] then _state[player].IsAlive = v end
end

function PlayerStateService.SetTeam(player, team)
	if _state[player] then _state[player].Team = team end
end

function PlayerStateService.SetChosenSide(player, side)
	if _state[player] then _state[player].ChosenSide = side end
end

function PlayerStateService.AddKill(player)
	if not _state[player] then return end
	_state[player].Kills += 1
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Kills") then
		ls.Kills.Value = _state[player].Kills
	end
end

function PlayerStateService.AddDamage(player, amount)
	if _state[player] then _state[player].DamageDealt += amount end
end

function PlayerStateService.AddWin(player)
	if not _state[player] then return end
	_state[player].Wins += 1
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Wins") then
		ls.Wins.Value = _state[player].Wins
	end
end

function PlayerStateService.AddCoins(player, amount)
	if not _state[player] then return end
	_state[player].Coins += amount
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		ls.Coins.Value = _state[player].Coins
	end
end

function PlayerStateService.GetAll()
	local result = {}
	for p in pairs(_state) do table.insert(result, p) end
	return result
end

function PlayerStateService.GetInRound()
	local result = {}
	for p, s in pairs(_state) do
		if s.InRound then table.insert(result, p) end
	end
	return result
end

function PlayerStateService.GetAliveInRound()
	local result = {}
	for p, s in pairs(_state) do
		if s.InRound and s.IsAlive then table.insert(result, p) end
	end
	return result
end

function PlayerStateService.ResetRoundState()
	for _, s in pairs(_state) do
		s.InRound = false
		s.IsAlive = false
		s.Team = Enums.Team.None
		s.ChosenSide = nil
		s.Kills = 0
		s.DamageDealt = 0
	end
end

return PlayerStateService