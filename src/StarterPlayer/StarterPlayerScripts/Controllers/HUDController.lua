-- HUDController.lua
-- Builds and manages the main HUD: status bar, timer, banners, result panel, HP bar.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIConfig     = require(game.ReplicatedStorage.Config.UIConfig)
local GameConfig   = require(game.ReplicatedStorage.Config.GameConfig)
local Utility      = require(game.ReplicatedStorage.Shared.Utility)
local Effects      = require(script.Parent.EffectsController)

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

local HUDController = {}

-- ScreenGui root
local _gui

-- Child references
local _statusLabel
local _timerLabel
local _bannerFrame
local _bannerLabel
local _resultFrame
local _resultTitle
local _resultBody
local _hpFrame
local _hpBar
local _hpLabel
local _testModeLabel

local function MakeLabel(parent, name, text, size, pos, font, textSize, color, anchorPoint)
	local lbl = Instance.new("TextLabel")
	lbl.Name               = name
	lbl.Text               = text
	lbl.Size               = size
	lbl.Position           = pos
	lbl.AnchorPoint        = anchorPoint or Vector2.new(0, 0)
	lbl.Font               = font or UIConfig.BODY_FONT
	lbl.TextSize           = textSize or 18
	lbl.TextColor3         = color or UIConfig.TEXT_PRIMARY
	lbl.BackgroundTransparency = 1
	lbl.TextStrokeTransparency = 0.5
	lbl.TextStrokeColor3   = Color3.new(0, 0, 0)
	lbl.Parent             = parent
	return lbl
end

local function MakeFrame(parent, name, size, pos, color, trans, anchorPoint)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	f.BackgroundColor3 = color or UIConfig.BACKGROUND_PANEL
	f.BackgroundTransparency = trans or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

function HUDController.Build()
	-- Destroy existing GUI if any (e.g. character respawn)
	if _gui then _gui:Destroy() end

	_gui = Instance.new("ScreenGui")
	_gui.Name              = "PartyPvPHUD"
	_gui.ResetOnSpawn      = false
	_gui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
	_gui.IgnoreGuiInset    = false
	_gui.Parent            = PlayerGui

	-- Top status bar
	local topBar = MakeFrame(_gui, "TopBar",
		UDim2.new(1, 0, 0, 44),
		UDim2.new(0, 0, 0, 0),
		UIConfig.BACKGROUND_DARK, 0.25)

	_statusLabel = MakeLabel(topBar, "StatusLabel", "Waiting...",
		UDim2.new(1, -140, 1, 0),
		UDim2.new(0, 8, 0, 0),
		UIConfig.BANNER_FONT, 20, UIConfig.TEXT_PRIMARY)
	_statusLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Timer (top right)
	_timerLabel = MakeLabel(topBar, "TimerLabel", "",
		UDim2.new(0, 120, 1, 0),
		UDim2.new(1, -128, 0, 0),
		UIConfig.BANNER_FONT, 22, UIConfig.TEXT_PRIMARY)
	_timerLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- TEST MODE label
	if GameConfig.TEST_MODE then
		_testModeLabel = MakeLabel(topBar, "TestMode", UIConfig.TEST_MODE_LABEL,
			UDim2.new(0, 120, 1, 0),
			UDim2.new(0.5, -60, 0, 0),
			UIConfig.BODY_FONT, 14, Color3.fromRGB(255, 200, 50))
		_testModeLabel.TextXAlignment = Enum.TextXAlignment.Center
	end

	-- HP bar (bottom left)
	_hpFrame = MakeFrame(_gui, "HPFrame",
		UDim2.new(0, 220, 0, 28),
		UDim2.new(0, 10, 1, -42),
		UIConfig.BACKGROUND_DARK, 0.3)
	_hpFrame.Visible = false

	local hpBg = MakeFrame(_hpFrame, "BG",
		UDim2.new(1, -60, 1, -8),
		UDim2.new(0, 4, 0, 4),
		Color3.fromRGB(60, 20, 20), 0)

	_hpBar = MakeFrame(hpBg, "Bar",
		UDim2.new(1, 0, 1, 0),
		UDim2.new(0, 0, 0, 0),
		Color3.fromRGB(60, 200, 60), 0)

	_hpLabel = MakeLabel(_hpFrame, "HPLabel", "HP",
		UDim2.new(0, 52, 1, 0),
		UDim2.new(1, -56, 0, 0),
		UIConfig.BODY_FONT, 15, UIConfig.TEXT_PRIMARY)
	_hpLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Center banner (phase name / big messages)
	_bannerFrame = MakeFrame(_gui, "BannerFrame",
		UDim2.new(0.6, 0, 0, 60),
		UDim2.new(0.2, 0, 0.08, 0),
		UIConfig.BACKGROUND_DARK, 0.3)
	_bannerFrame.Visible = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = _bannerFrame

	_bannerLabel = MakeLabel(_bannerFrame, "BannerLabel", "",
		UDim2.new(1, -16, 1, 0),
		UDim2.new(0, 8, 0, 0),
		UIConfig.BANNER_FONT, 26, UIConfig.TEXT_PRIMARY)
	_bannerLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Result panel (shown at Victory/Celebration)
	_resultFrame = MakeFrame(_gui, "ResultFrame",
		UDim2.new(0, 400, 0, 180),
		UDim2.new(0.5, -200, 0.35, 0),
		UIConfig.BACKGROUND_PANEL, 0.1)
	_resultFrame.Visible = false

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 12)
	rCorner.Parent = _resultFrame

	_resultTitle = MakeLabel(_resultFrame, "Title", "",
		UDim2.new(1, -16, 0, 60),
		UDim2.new(0, 8, 0, 8),
		UIConfig.BANNER_FONT, 36, UIConfig.TEXT_PRIMARY)
	_resultTitle.TextXAlignment = Enum.TextXAlignment.Center

	_resultBody = MakeLabel(_resultFrame, "Body", "",
		UDim2.new(1, -16, 0, 60),
		UDim2.new(0, 8, 0, 70),
		UIConfig.BODY_FONT, 20, UIConfig.TEXT_SECONDARY)
	_resultBody.TextXAlignment = Enum.TextXAlignment.Center
end

function HUDController.SetStatus(text)
	if _statusLabel then
		_statusLabel.Text = text
	end
end

function HUDController.SetTimer(seconds)
	if _timerLabel then
		_timerLabel.Text = Utility.FormatTime(seconds)
	end
end

function HUDController.ClearTimer()
	if _timerLabel then _timerLabel.Text = "" end
end

function HUDController.ShowBanner(text, color, duration)
	if not _bannerFrame then return end
	_bannerLabel.Text = text
	if color then
		_bannerLabel.TextColor3 = color
	else
		_bannerLabel.TextColor3 = UIConfig.TEXT_PRIMARY
	end
	_bannerFrame.Visible = true
	_bannerFrame.BackgroundTransparency = 0.3
	if duration and duration > 0 then
		task.delay(duration, function()
			if _bannerFrame then
				_bannerFrame.Visible = false
			end
		end)
	end
end

function HUDController.HideBanner()
	if _bannerFrame then
		_bannerFrame.Visible = false
	end
end

function HUDController.ShowResult(titleText, bodyText, titleColor)
	if not _resultFrame then return end
	_resultTitle.Text = titleText
	_resultTitle.TextColor3 = titleColor or UIConfig.TEXT_PRIMARY
	_resultBody.Text  = bodyText
	_resultFrame.Visible = true
	_resultFrame.BackgroundTransparency = 1
	Effects.FadeTo(_resultFrame, 0.1, UIConfig.TWEEN_MEDIUM)
end

function HUDController.HideResult()
	if _resultFrame then
		Effects.HideFrame(_resultFrame, UIConfig.TWEEN_MEDIUM)
	end
end

function HUDController.ShowHP(current, max)
	if not _hpFrame then return end
	_hpFrame.Visible = true
	local ratio = math.max(0, math.min(1, current / max))
	TweenService:Create(_hpBar, TweenInfo.new(0.2), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
	_hpLabel.Text = tostring(math.floor(current))
	-- Color HP bar: green -> yellow -> red
	local r = math.floor(Utility.Lerp(60, 200, 1 - ratio))
	local g = math.floor(Utility.Lerp(200, 60, 1 - ratio))
	_hpBar.BackgroundColor3 = Color3.fromRGB(r, g, 40)
end

function HUDController.HideHP()
	if _hpFrame then _hpFrame.Visible = false end
end

function HUDController.ShowMessage(text, duration)
	HUDController.ShowBanner(text, UIConfig.TEXT_SECONDARY, duration or 3)
end

return HUDController