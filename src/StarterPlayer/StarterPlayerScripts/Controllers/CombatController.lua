-- CombatController.lua
-- Captures player input during Battle phase and fires CombatInput to server.
-- Manages local cooldown feedback only (cosmetic).

local Players      = game:GetService("Players")
local UserInputSvc = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local CombatConfig = require(game.ReplicatedStorage.Config.CombatConfig)
local Enums        = require(game.ReplicatedStorage.Shared.Enums)
local UIConfig     = require(game.ReplicatedStorage.Config.UIConfig)

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Remotes      = game.ReplicatedStorage.Remotes

local CombatController = {}

local _active          = false
local _attackCooldown  = false
local _dashCooldown    = false
local _blockCooldown   = false
local _blocking        = false

-- UI elements
local _gui
local _attackBtn
local _dashBtn
local _blockBtn

local function SetCooldownVisual(btn, duration)
	if not btn then return end
	btn.BackgroundTransparency = 0.6
	task.delay(duration, function()
		if btn then btn.BackgroundTransparency = 0.1 end
	end)
end

local function BuildCombatHUD()
	if _gui then _gui:Destroy() end

	_gui = Instance.new("ScreenGui")
	_gui.Name           = "CombatHUD"
	_gui.ResetOnSpawn   = false
	_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_gui.Parent         = PlayerGui

	local function MakeBtn(name, text, pos, color)
		local btn = Instance.new("TextButton")
		btn.Name               = name
		btn.Size               = UDim2.new(0, 80, 0, 80)
		btn.Position           = pos
		btn.AnchorPoint        = Vector2.new(0.5, 1)
		btn.BackgroundColor3   = color
		btn.BackgroundTransparency = 0.1
		btn.BorderSizePixel    = 0
		btn.Font               = UIConfig.BANNER_FONT
		btn.TextSize           = 14
		btn.TextColor3         = UIConfig.TEXT_PRIMARY
		btn.Text               = text
		btn.Visible            = false
		btn.Parent             = _gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.