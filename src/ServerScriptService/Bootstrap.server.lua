-- Bootstrap.server.lua
-- Entry point: initialises all services and starts the round loop.

local Players        = game:GetService("Players")
local PlayerStateSvc = require(script.Parent.Services.PlayerStateService)
local RoundService   = require(script.Parent.Services.RoundService)

-- Wire player lifecycle
Players.PlayerAdded:Connect(function(player)
	PlayerStateSvc.OnPlayerAdded(player)
	-- Respawn character if needed
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	-- RoundService also connects this for mid-round cleanup.
	-- PlayerStateService cleanup is idempotent.
	PlayerStateSvc.OnPlayerRemoving(player)
end)

-- Register any players already in the server (rare edge case in Studio)
for _, player in ipairs(Players:GetPlayers()) do
	PlayerStateSvc.OnPlayerAdded(player)
end

-- Start the round system
RoundService.Init()

print("[Bootstrap] PartyPvP server started.")