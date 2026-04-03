-- Bootstrap.server.lua

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ===== Ensure Remotes folder =====
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes        = Instance.new("Folder")
	remotes.Name   = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name)
	local r = remotes:FindFirstChild(name)
	if not r then
		r        = Instance.new("RemoteEvent")
		r.Name   = name
		r.Parent = remotes
	end
	return r
end

ensureRemote("RoundState")
ensureRemote("ShowChoices")
ensureRemote("SubmitChoice")
ensureRemote("CombatInput")
ensureRemote("RoundResult")
ensureRemote("HUDMessage")
ensureRemote("PlayCelebration")
ensureRemote("SyncDarkness")

print("[Bootstrap] Remotes готовы.")

-- ===== Safe require with error reporting =====
local function safeRequire(moduleScript, label)
	local ok, result = pcall(require, moduleScript)
	if not ok then
		error("[Bootstrap] FAILED to require " .. label .. ": " .. tostring(result), 2)
	end
	if type(result) ~= "table" then
		error("[Bootstrap] Module " .. label .. " did not return a table! Got: " .. type(result), 2)
	end
	print("[Bootstrap] Loaded: " .. label)
	return result
end

-- ===== Load services =====
local Services = ServerScriptService:WaitForChild("Services", 10)
if not Services then
	error("[Bootstrap] ServerScriptService.Services folder not found!")
end

local function getService(name)
	local mod = Services:FindFirstChild(name)
	if not mod then
		error("[Bootstrap] Service ModuleScript not found: " .. name)
	end
	return safeRequire(mod, name)
end

local ValidationService    = getService("ValidationService")
local PlayerStateService   = getService("PlayerStateService")
local ChoiceService        = getService("ChoiceService")
local TeleportServiceLocal = getService("TeleportServiceLocal")
local TeamService          = getService("TeamService")
local CombatService        = getService("CombatService")
local RewardService        = getService("RewardService")
local CelebrationService   = getService("CelebrationService")
local RoundService         = getService("RoundService")

-- ===== Validate required functions exist =====
local function assertFn(service, fnName, label)
	if type(service[fnName]) ~= "function" then
		error("[Bootstrap] " .. label .. " is missing function: " .. fnName)
	end
end

assertFn(PlayerStateService,   "Init",          "PlayerStateService")
assertFn(TeleportServiceLocal, "Init",          "TeleportServiceLocal")
assertFn(CombatService,        "Init",          "CombatService")
assertFn(RoundService,         "Init",          "RoundService")
assertFn(RoundService,         "StartLoop",     "RoundService")

-- ===== Initialize =====
PlayerStateService.Init()
TeleportServiceLocal.Init(PlayerStateService)
CombatService.Init(PlayerStateService, TeamService)

RoundService.Init(
	PlayerStateService,
	ChoiceService,
	TeleportServiceLocal,
	TeamService,
	CombatService,
	RewardService,
	CelebrationService,
	ValidationService
)

print("[Bootstrap] Все сервисы инициализированы. Запускаем раунд.")

-- ===== Start round loop =====
task.spawn(function()
	RoundService.StartLoop()
end)