-- ModuleScript
-- Client-side: captures input and sends CombatInput to server.
-- Does NOT do damage, does NOT create buttons (buttons optional/HUD only).

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums        = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CombatConfig"))

local Remotes     = ReplicatedStorage:WaitForChild("Remotes", 15)
local CombatInput = Remotes and Remotes:WaitForChild("CombatInput", 10)

local CombatController = {}

local localPlayer  = Players.LocalPlayer
local combatActive = false

local lastAttack = 0
local lastDash   = 0
local lastBlock  = 0

local function findClosestEnemy()
	local char = localPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local best     = CombatConfig.ATTACK_RANGE
	local bestPlayer = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player == localPlayer then continue end
		local oc = player.Character
		if not oc then continue end
		local oh = oc:FindFirstChild("HumanoidRootPart")
		if not oh then continue end
		local dist = (hrp.Position - oh.Position).Magnitude
		if dist < best then
			best       = dist
			bestPlayer = player
		end
	end

	return bestPlayer
end

local function sendMelee()
	if not CombatInput then return end
	local now = tick()
	if now - lastAttack < CombatConfig.ATTACK_COOLDOWN then return end
	lastAttack = now
	local target = findClosestEnemy()
	if not target then return end
	CombatInput:FireServer({ Action = Enums.CombatAction.Melee, TargetId = target.UserId })
end

local function sendDash()
	if not CombatInput then return end
	local now = tick()
	if now - lastDash < CombatConfig.DASH_COOLDOWN then return end
	lastDash = now
	CombatInput:FireServer({ Action = Enums.CombatAction.Dash })
end

local function sendBlock()
	if not CombatInput then return end
	local now = tick()
	if now - lastBlock < CombatConfig.BLOCK_COOLDOWN then return end
	lastBlock = now
	CombatInput:FireServer({ Action = Enums.CombatAction.Block })
end

function CombatController.SetActive(active)
	combatActive = active
end

function CombatController.Init()
	if not CombatInput then
		warn("[CombatController] CombatInput remote not found")
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not combatActive then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.F then
			sendMelee()
		elseif input.KeyCode == Enum.KeyCode.Q then
			sendDash()
		elseif input.KeyCode == Enum.KeyCode.E then
			sendBlock()
		end
	end)

	print("[CombatController] Initialized. Keys: F/Click=Attack, Q=Dash, E=Block")
end

return CombatController