-- DarknessController.lua
-- Applies a screen-darkening overlay and locally hides other players
-- during the DarkChoice phase.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

local DarknessController = {}

local _gui
local _overlay
local _originalTransparencies = {}  -- { [character part] = originalLocalTransparency }
local _originalBrightness
local _originalAmbient

local DARKNESS_TRANS = 0.65   -- overlay transparency (lower = darker)
local FADE_DURATION  = 0.8

local function BuildOverlay()
	if _gui then _gui:Destroy() end
	_gui = Instance.new("ScreenGui")
	_gui.Name           = "DarknessGui"
	_gui.ResetOnSpawn   = false
	_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_gui.IgnoreGuiInset = true
	_gui.DisplayOrder   = 100
	_gui.Parent         = PlayerGui

	_overlay = Instance.new("Frame")
	_overlay.Name                 = "Overlay"
	_overlay.Size                 = UDim2.new(1, 0, 1, 0)
	_overlay.Position             = UDim2.new(0, 0, 0, 0)
	_overlay.BackgroundColor3     = Color3.new(0, 0, 0)
	_overlay.BackgroundTransparency = 1
	_overlay.BorderSizePixel      = 0
	_overlay.ZIndex               = 100
	_overlay.Visible              = false
	_overlay.Parent               = _gui
end

local function HideOtherPlayers()
	_originalTransparencies = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			for _, desc in ipairs(player.Character:GetDescendants()) do
				if desc:IsA("BasePart") or desc:IsA("Decal") then
					_originalTransparencies[desc] = desc.LocalTransparencyModifier
					desc.LocalTransparencyModifier = 1
				end
			end
		end
	end
end

local function ShowOtherPlayers()
	for desc, orig in pairs(_originalTransparencies) do
		if desc and desc.Parent then
			desc.LocalTransparencyModifier = orig
		end
	end
	_originalTransparencies = {}
end

function DarknessController.Begin()
	if not _overlay then BuildOverlay() end
	_overlay.Visible = true
	TweenService:Create(_overlay, TweenInfo.new(FADE_DURATION), {
		BackgroundTransparency = DARKNESS_TRANS
	}):Play()

	-- Save and dim ambient lighting
	_originalBrightness = Lighting.Brightness
	_originalAmbient    = Lighting.Ambient
	TweenService:Create(Lighting, TweenInfo.new(FADE_DURATION), {
		Brightness = 0.1,
		Ambient    = Color3.fromRGB(5, 5, 15),
	}):Play()

	-- Hide other players shortly after overlay starts
	task.delay(FADE_DURATION * 0.5, HideOtherPlayers)
end

function DarknessController.End()
	if not _overlay then return end
	ShowOtherPlayers()
	TweenService:Create(_overlay, TweenInfo.new(FADE_DURATION), {
		BackgroundTransparency = 1
	}):Play()
	task.delay(FADE_DURATION, function()
		if _overlay then _overlay.Visible = false end
	end)

	-- Restore lighting
	if _originalBrightness then
		TweenService:Create(Lighting, TweenInfo.new(FADE_DURATION), {
			Brightness = _originalBrightness,
			Ambient    = _originalAmbient or Color3.fromRGB(70, 70, 70),
		}):Play()
	end
end

function DarknessController.Init()
	BuildOverlay()
end

return DarknessController