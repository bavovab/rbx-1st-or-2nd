local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Создаём все RemoteEvents ДО старта round loop
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local REMOTE_NAMES = {
	"PhaseChanged",
	"TimerUpdate",
	"ChoiceRevealA",
	"ChoiceRevealB",
	"DarknessBegin",
	"DarknessEnd",
	"TeamAssigned",
	"BattleStart",
	"PlayerEliminated",
	"VictoryAnnounced",
	"CelebrationStart",
	"RoundResult",
	"HUDMessage",
	"HPUpdate",
	"SubmitChoice",
	"CombatInput",
	"LeaderboardUpdate",
}

for _, name in ipairs(REMOTE_NAMES) do
	if not RemotesFolder:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name   = name
		re.Parent = RemotesFolder
	end
end

-- Запускаем сервисы
local PlayerStateSvc     = require(script.Parent.Services.PlayerStateService)
local RoundService       = require(script.Parent.Services.RoundService)
local LeaderboardService = require(script.Parent.Services.LeaderboardService)

Players.PlayerAdded:Connect(function(player)
	PlayerStateSvc.OnPlayerAdded(player)
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerStateSvc.OnPlayerRemoving(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	PlayerStateSvc.OnPlayerAdded(player)
end

RoundService.Init()
LeaderboardService.Init()

print("[Bootstrap] PartyPvP server started.")