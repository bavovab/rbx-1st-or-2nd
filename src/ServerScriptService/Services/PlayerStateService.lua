-- PlayerStateService.lua
-- Manages per-player state and leaderstats for all players.

local Players  = game:GetService("Players")
local Enums    = require(game.ReplicatedStorage.Shared.Enums)

local PlayerStateService = {}

-- state[player] = {
--   InRound     : bool,
--   IsAlive     : bool,
--   Team        : Enums.Team.*,
--   ChosenSide  : "Left"|"Right"|nil,
--   Kills       : number,
--   DamageDealt : number,
--   Wins        : number,
--   Coins       : number,
-- }
local _state = {}

local function MakeLeaderstats(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = ls

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = ls

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = ls
end

function PlayerStateService.OnPlayerAdded(player)
	_state[player] = {
		InRound     = false,
		IsAlive     = false,
		Team        = Enums.Team.None,
		ChosenSide  = nil,
		Kills       = 0,
		DamageDealt = 0,
		Wins        = 0,
		Coins       = 0,
	}
	MakeLeaderstats(player)
end

function PlayerStateService.OnPlayerRemoving(player)
	_state[player] = nil
end

function PlayerStateService.Get(player)
	return _state[player]
end

function PlayerStateService.SetInRound(player, inRound)
	if _state[player] then
		_state[player].InRound = inRound
		if not inRound then
			_state[player].IsAlive     = false
			_state[player].Team        = Enums.Team.None
			_state[player].ChosenSide  = nil
		end
	end
end

function PlayerStateService.SetAlive(player, alive)
	if _state[player] then
		_state[player].IsAlive = alive
	end
end

function PlayerStateService.SetTeam(player, team)
	if _state[player] then
		_state[player].Team = team
	end
end

function PlayerStateService.SetChosenSide(player, side)
	if _state[player] then
		_state[player].ChosenSide = side
	end
end

function PlayerStateService.AddKill(player)
	if _state[player] then
		_state[player].Kills = _state[player].Kills + 1
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local k = ls:FindFirstChild("Kills")
			if k then k.Value = _state[player].Kills end
		end
	end
end

function PlayerStateService.AddDamage(player, amount)
	if _state[player] then
		_state[player].DamageDealt = _state[player].DamageDealt + amount
	end
end

function PlayerStateService.AddWin(player)
	if _state[player] then
		_state[player].Wins = _state[player].Wins + 1
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local w = ls:FindFirstChild("Wins")
			if w then w.Value = _state[player].Wins end
		end
	end
end

function PlayerStateService.AddCoins(player, amount)
	if _state[player] then
		_state[player].Coins = _state[player].Coins + amount
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local c = ls:FindFirstChild("Coins")
			if c then c.Value = _state[player].Coins end
		end
	end
end

-- Returns list of all players currently tracked
function PlayerStateService.GetAll()
	local list = {}
	for p in pairs(_state) do
		table.insert(list, p)
	end
	return list
end

-- Returns list of players flagged InRound
function PlayerStateService.GetInRound()
	local list = {}
	for p, s in pairs(_state) do
		if s.InRound then
			table.insert(list, p)
		end
	end
	return list
end

-- Returns list of players flagged InRound and IsAlive
function PlayerStateService.GetAliveInRound()
	local list = {}
	for p, s in pairs(_state) do
		if s.InRound and s.IsAlive then
			table.insert(list, p)
		end
	end
	return list
end

-- Resets per-round fields for all currently tracked players
function PlayerStateService.ResetRoundState()
	for p, s in pairs(_state) do
		s.InRound    = false
		s.IsAlive    = false
		s.Team       = Enums.Team.None
		s.ChosenSide = nil
	end
end

return PlayerStateService