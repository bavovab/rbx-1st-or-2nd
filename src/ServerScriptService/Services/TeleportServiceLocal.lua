-- ModuleScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Config     = ReplicatedStorage:WaitForChild("Config")
local Utility    = require(Shared:WaitForChild("Utility"))
local GameConfig = require(Config:WaitForChild("GameConfig"))

local TeleportServiceLocal = {}

local PlayerStateService  -- injected via Init

local function getFolder(pathList)
	local current = workspace
	for _, name in ipairs(pathList) do
		if not current then return nil end
		current = current:FindFirstChild(name)
	end
	return current
end

local function getSpawnCFrames(folder)
	local cframes = {}
	if not folder then return cframes end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(cframes, child.CFrame + Vector3.new(0, 3, 0))
		end
	end
	return cframes
end

local function pickSpawn(cframes, index)
	if #cframes == 0 then
		return CFrame.new(0, 10, 0)
	end
	local i = ((index - 1) % #cframes) + 1
	return cframes[i]
end

function TeleportServiceLocal.Init(pss)
	PlayerStateService = pss
	print("[TeleportServiceLocal] Initialized.")
end

function TeleportServiceLocal.SaveAllPositions(players)
	for _, player in ipairs(players) do
		PlayerStateService.SavePosition(player)
	end
end

function TeleportServiceLocal.TeleportToPreArena(players)
	local folder  = getFolder({"Arena", "PreArenaSpawnPoints"})
	local cframes = getSpawnCFrames(folder)

	for i, player in ipairs(players) do
		local char = player.Character
		if not char then continue end
		if #cframes > 0 then
			char:PivotTo(pickSpawn(cframes, i))
		else
			char:PivotTo(CFrame.new((i - 1) * 5, 10, 0))
		end
	end
end

function TeleportServiceLocal.TeleportTeamToBattle(teamPlayers, side)
	local folderName = (side == "Left") and "TeamLeftSpawnPoints" or "TeamRightSpawnPoints"
	local folder     = getFolder({"Arena", folderName})
	local cframes    = getSpawnCFrames(folder)

	for i, player in ipairs(teamPlayers) do
		local char = player.Character
		if not char then continue end
		if #cframes > 0 then
			char:PivotTo(pickSpawn(cframes, i))
		else
			local x = (side == "Left") and -25 or 25
			char:PivotTo(CFrame.new(x + (i - 1) * 3, 10, 0))
		end
	end
end

function TeleportServiceLocal.ReturnAllToLobby(players)
	local lobbyFolder  = getFolder({"Lobby", "SpawnPoints"})
	local lobbyCFrames = getSpawnCFrames(lobbyFolder)

	for i, player in ipairs(players) do
		local char = player.Character
		if not char then continue end

		local saved = PlayerStateService.GetSavedCFrame(player)
		if saved then
			char:PivotTo(saved)
		elseif #lobbyCFrames > 0 then
			char:PivotTo(pickSpawn(lobbyCFrames, i))
		else
			char:PivotTo(GameConfig.LOBBY_FALLBACK_CFRAME)
		end
	end
end

return TeleportServiceLocal