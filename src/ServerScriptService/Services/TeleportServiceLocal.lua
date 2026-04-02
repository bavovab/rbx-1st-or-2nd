-- TeleportServiceLocal.lua
-- Handles all in-game teleportation. Saves and restores player positions.

local Players  = game:GetService("Players")
local Utility  = require(game.ReplicatedStorage.Shared.Utility)

local TeleportServiceLocal = {}

-- Saved lobby positions per player: { CFrame }
local _savedPositions = {}

-- Waits for character to load with timeout
local function WaitForCharacter(player, timeout)
	local t = 0
	while not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") do
		task.wait(0.1)
		t = t + 0.1
		if t >= timeout then return false end
	end
	return true
end

-- Collects all SpawnPoint CFrames under a folder (Parts named SpawnPoint or any Part)
local function GetSpawnCFrames(folder)
	local cframes = {}
	if not folder then return cframes end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(cframes, child.CFrame + Vector3.new(0, 3, 0))
		end
	end
	return cframes
end

local function TeleportPlayerTo(player, cf)
	local root = Utility.GetHumanoidRootPart(player)
	if root then
		root.CFrame = cf
	end
end

-- Save player's current lobby position before entering arena
function TeleportServiceLocal.SavePosition(player)
	local root = Utility.GetHumanoidRootPart(player)
	if root then
		_savedPositions[player] = root.CFrame
	end
end

function TeleportServiceLocal.ClearSavedPosition(player)
	_savedPositions[player] = nil
end

-- Teleport all InRound players to pre-arena spawn points
function TeleportServiceLocal.TeleportToPreArena(players)
	local folder = Utility.FindPath(workspace, {"Arena", "PreArenaSpawnPoints"})
	local cframes = GetSpawnCFrames(folder)
	if #cframes == 0 then
		-- Fallback: use Arena stage center
		local stage = Utility.FindPath(workspace, {"Arena", "Stage"})
		if stage and stage:IsA("BasePart") then
			cframes = { stage.CFrame + Vector3.new(0, 5, 0) }
		else
			cframes = { CFrame.new(0, 10, 0) }
		end
	end
	for i, player in ipairs(players) do
		local cf = cframes[((i - 1) % #cframes) + 1]
		-- Spread players slightly
		local offset = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
		TeleportPlayerTo(player, cf + offset)
	end
end

-- Teleport a team to their battle side spawns
function TeleportServiceLocal.TeleportTeamToBattle(players, teamSide)
	local folderName = (teamSide == "Left") and "TeamLeftSpawnPoints" or "TeamRightSpawnPoints"
	local folder = Utility.FindPath(workspace, {"Arena", folderName})
	local cframes = GetSpawnCFrames(folder)
	if #cframes == 0 then
		-- Fallback positions
		local x = (teamSide == "Left") and -30 or 30
		cframes = { CFrame.new(x, 10, 0) }
	end
	for i, player in ipairs(players) do
		local cf = cframes[((i - 1) % #cframes) + 1]
		local offset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
		TeleportPlayerTo(player, cf + offset)
		-- Reset camera focus by briefly enabling CharacterAutoLoads pattern
		local hum = Utility.GetHumanoid(player)
		if hum then
			hum.AutoRotate = true
		end
	end
end

-- Return all players to their saved positions (or fallback lobby spawn)
function TeleportServiceLocal.ReturnAllToLobby(players)
	local lobbyFolder = Utility.FindPath(workspace, {"Lobby", "SpawnPoints"})
	local fallbackCFrames = GetSpawnCFrames(lobbyFolder)
	if #fallbackCFrames == 0 then
		fallbackCFrames = { CFrame.new(0, 5, 0) }
	end
	for i, player in ipairs(players) do
		if _savedPositions[player] then
			TeleportPlayerTo(player, _savedPositions[player])
			_savedPositions[player] = nil
		else
			local cf = fallbackCFrames[((i - 1) % #fallbackCFrames) + 1]
			TeleportPlayerTo(player, cf)
		end
	end
end

-- Return a single player to lobby (used when they leave mid-round, handled elsewhere,
-- or for Eliminate undecided mode)
function TeleportServiceLocal.ReturnPlayerToLobby(player)
	if _savedPositions[player] then
		TeleportPlayerTo(player, _savedPositions[player])
		_savedPositions[player] = nil
	else
		local lobbyFolder = Utility.FindPath(workspace, {"Lobby", "SpawnPoints"})
		local fallbacks = GetSpawnCFrames(lobbyFolder)
		if #fallbacks > 0 then
			TeleportPlayerTo(player, fallbacks[1])
		else
			TeleportPlayerTo(player, CFrame.new(0, 5, 0))
		end
	end
end

return TeleportServiceLocal