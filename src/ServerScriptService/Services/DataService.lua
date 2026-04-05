-- ModuleScript: ServerScriptService/Services/DataService.lua

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local HUDMessage = Remotes:WaitForChild("HUDMessage")

local DataService = {}

local PlayerStore = DataStoreService:GetDataStore("PlayerStats_v1")

-- Кэш { [userId] = { Wins, Coins, Kills } }
local cache = {}

local DEFAULT_DATA = {
	Wins  = 0,
	Coins = 0,
	Kills = 0,
}

-----------------------------------------------------------------------
-- Внутренние хелперы
-----------------------------------------------------------------------

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do copy[k] = v end
	return copy
end

local function loadData(player)
	local uid = tostring(player.UserId)
	local ok, result = pcall(function()
		return PlayerStore:GetAsync(uid)
	end)

	if ok and type(result) == "table" then
		local data = deepCopy(DEFAULT_DATA)
		for k in pairs(DEFAULT_DATA) do
			if result[k] ~= nil then data[k] = result[k] end
		end
		cache[player.UserId] = data
		print(string.format("[DataService] Загружено для %s: Wins=%d Coins=%d Kills=%d",
			player.Name, data.Wins, data.Coins, data.Kills))
	else
		if not ok then
			warn(string.format("[DataService] Ошибка загрузки для %s: %s", player.Name, tostring(result)))
		end
		cache[player.UserId] = deepCopy(DEFAULT_DATA)
		print(string.format("[DataService] Новый профиль для %s", player.Name))
	end

	-- Синхронизируем leaderstats
	DataService.SyncLeaderstats(player)
end

local function saveData(player)
	local uid  = tostring(player.UserId)
	local data = cache[player.UserId]
	if not data then return end

	local ok, err = pcall(function()
		PlayerStore:SetAsync(uid, data)
	end)

	if ok then
		print(string.format("[DataService] Сохранено для %s: Wins=%d Coins=%d Kills=%d",
			player.Name, data.Wins, data.Coins, data.Kills))
	else
		warn(string.format("[DataService] Ошибка сохранения для %s: %s", player.Name, tostring(err)))
	end
end

-----------------------------------------------------------------------
-- Leaderstats
-----------------------------------------------------------------------

function DataService.SyncLeaderstats(player)
	local data = cache[player.UserId]
	if not data then return end

	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls      = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end

	local function syncVal(name, value)
		local v = ls:FindFirstChild(name)
		if not v then
			v       = Instance.new("IntValue")
			v.Name  = name
			v.Parent = ls
		end
		v.Value = value
	end

	syncVal("Wins",   data.Wins)
	syncVal("Coins",  data.Coins)
	syncVal("Kills",  data.Kills)
end

-----------------------------------------------------------------------
-- Публичный API
-----------------------------------------------------------------------

function DataService.Init()
	Players.PlayerAdded:Connect(function(player)
		loadData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveData(player)
		cache[player.UserId] = nil
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end)

	-- Для игроков уже в игре
	for _, player in ipairs(Players:GetPlayers()) do
		if not cache[player.UserId] then
			loadData(player)
		end
	end

	print("[DataService] Initialized.")
end

function DataService.GetData(player)
	local data = cache[player.UserId]
	if not data then return deepCopy(DEFAULT_DATA) end
	return deepCopy(data)
end

function DataService.AddWin(player, amount)
	local data = cache[player.UserId]
	if not data then return end
	data.Wins = data.Wins + (amount or 1)
	DataService.SyncLeaderstats(player)
	print(string.format("[DataService] %s Wins -> %d", player.Name, data.Wins))
end

function DataService.AddCoins(player, amount)
	local data = cache[player.UserId]
	if not data then return end
	data.Coins = data.Coins + (amount or 0)
	DataService.SyncLeaderstats(player)
	print(string.format("[DataService] %s Coins -> %d", player.Name, data.Coins))
end

function DataService.AddKill(player, amount)
	local data = cache[player.UserId]
	if not data then return end
	data.Kills = data.Kills + (amount or 1)
	DataService.SyncLeaderstats(player)
	print(string.format("[DataService] %s Kills -> %d", player.Name, data.Kills))
end

function DataService.Save(player)
	saveData(player)
end

function DataService.SaveAll()
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end

return DataService