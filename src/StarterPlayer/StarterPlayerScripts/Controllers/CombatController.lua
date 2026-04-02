local Players      = game:GetService("Players")
local UserInputSvc = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local CombatConfig = require(game.ReplicatedStorage.Config.CombatConfig)
local Enums        = require(game.ReplicatedStorage.Shared.Enums)
local UIConfig     = require(game.ReplicatedStorage.Config.UIConfig)

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

local RemotesFolder = game.ReplicatedStorage:WaitForChild("Remotes")
local RemoteCombat  = RemotesFolder:WaitForChild("CombatInput")

local CombatController = {}

local _active         = false
local _attackCooldown = false
local _dashCooldown   = false
local _blockCooldown  = false

local _gui
local _attackBtn
local _dashBtn
local _blockBtn

local function SetCooldownVisual(btn, duration)
	if not btn then return end
	btn.BackgroundTransparency = 0.6
	task.delay(duration, function()
		if btn then
			btn.BackgroundTransparency = 0.1
		end
	end)
end

local function MakeBtn(name, text, pos, color)
	local btn = Instance.new("TextButton")
	btn.Name                 = name
	btn.Size                 = UDim2.new(0, 80, 0, 80)
	btn.Position             = pos
	btn.AnchorPoint          = Vector2.new(0.5, 1)
	btn.BackgroundColor3     = color
	btn.BackgroundTransparency = 0.1
	btn.BorderSizePixel      = 0
	btn.Font                 = UIConfig.BANNER_FONT
	btn.TextSize             = 14
	btn.TextColor3           = UIConfig.TEXT_PRIMARY
	btn.Text                 = text
	btn.Visible              = false
	btn.Parent               = _gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn
	return btn
end

local function BuildCombatHUD()
	if _gui then _gui:Destroy() end

	_gui = Instance.new("ScreenGui")
	_gui.Name           = "CombatHUD"
	_gui.ResetOnSpawn   = false
	_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_gui.Parent         = PlayerGui

	_attackBtn = MakeBtn("AttackBtn", "ATTACK\n[E]",
		UDim2.new(0.5, -50, 1, -20),
		Color3.fromRGB(200, 60, 60))

	_dashBtn = MakeBtn("DashBtn", "DASH\n[Q]",
		UDim2.new(0.5, -140, 1, -20),
		Color3.fromRGB(60, 120, 200))

	_blockBtn = MakeBtn("BlockBtn", "BLOCK\n[R]",
		UDim2.new(0.5, 40, 1, -20),
		Color3.fromRGB(60, 180, 60))

	-- Button click handlers
	_attackBtn.Activated:Connect(function()
		if _active and not _attackCooldown then
			_attackCooldown = true
			SetCooldownVisual(_attackBtn, CombatConfig.ATTACK_COOLDOWN)
			RemoteCombat:FireServer(Enums.CombatAction.Attack, nil)
			task.delay(CombatConfig.ATTACK_COOLDOWN, function()
				_attackCooldown = false
			end)
		end
	end)

	_dashBtn.Activated:Connect(function()
		if _active and not _dashCooldown then
			_dashCooldown = true
			SetCooldownVisual(_dashBtn, CombatConfig.DASH_COOLDOWN)
			RemoteCombat:FireServer(Enums.CombatAction.Dash, nil)
			task.delay(CombatConfig.DASH_COOLDOWN, function()
				_dashCooldown = false
			end)
		end
	end)

	_blockBtn.Activated:Connect(function()
		if _active and not _blockCooldown then
			_blockCooldown = true
			SetCooldownVisual(_blockBtn, CombatConfig.BLOCK_COOLDOWN)
			RemoteCombat:FireServer(Enums.CombatAction.Block, nil)
			task.delay(CombatConfig.BLOCK_COOLDOWN, function()
				_blockCooldown = false
			end)
		end
	end)
end

function CombatController.SetActive(active)
	_active = active
	if _attackBtn then _attackBtn.Visible = active end
	if _dashBtn   then _dashBtn.Visible   = active end
	if _blockBtn  then _blockBtn.Visible  = active end
	if not active then
		_attackCooldown = false
		_dashCooldown   = false
		_blockCooldown  = false
	end
end

function CombatController.Init()
	BuildCombatHUD()

	UserInputSvc.InputBegan:Connect(function(input, processed)
		if processed or not _active then return end

		if input.KeyCode == Enum.KeyCode.E then
			if not _attackCooldown then
				_attackCooldown = true
				SetCooldownVisual(_attackBtn, CombatConfig.ATTACK_COOLDOWN)
				RemoteCombat:FireServer(Enums.CombatAction.Attack, nil)
				task.delay(CombatConfig.ATTACK_COOLDOWN, function()
					_attackCooldown = false
				end)
			end

		elseif input.KeyCode == Enum.KeyCode.Q then
			if not _dashCooldown then
				_dashCooldown = true
				SetCooldownVisual(_dashBtn, CombatConfig.DASH_COOLDOWN)
				RemoteCombat:FireServer(Enums.CombatAction.Dash, nil)
				task.delay(CombatConfig.DASH_COOLDOWN, function()
					_dashCooldown = false
				end)
			end

		elseif input.KeyCode == Enum.KeyCode.R then
			if not _blockCooldown then
				_blockCooldown = true
				SetCooldownVisual(_blockBtn, CombatConfig.BLOCK_COOLDOWN)
				RemoteCombat:FireServer(Enums.CombatAction.Block, nil)
				task.delay(CombatConfig.BLOCK_COOLDOWN, function()
					_blockCooldown = false
				end)
			end
		end
	end)
end

return CombatController