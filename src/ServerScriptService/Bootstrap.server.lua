local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ждём пока Remotes папка появится и init.server.lua создаст все события
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
repeat task.wait() until Remotes:FindFirstChild("SubmitChoice")

local PlayerStateSvc = require(script.Parent.Services.PlayerStateService)
local RoundService   = require(script.Parent.Services.RoundService)

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

print("[Bootstrap] PartyPvP server started.")