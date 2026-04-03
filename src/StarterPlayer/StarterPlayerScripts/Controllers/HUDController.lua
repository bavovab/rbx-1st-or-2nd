-- ModuleScript
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("UIConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local HUDController = {}

local gui, topStatus, timerLabel, roundBanner, resultPanel, resultLabel, fadeFrame

local function waitForGui()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui         = playerGui:WaitForChild("MainHUD", 15)
	if not gui then
		warn("[HUDController] MainHUD not found!")
		return false
	end
	topStatus   = gui:WaitForChild("TopStatus",   5)
	timerLabel  = gui:WaitForChild("TimerLabel",  5)
	roundBanner = gui:WaitForChild("RoundBanner", 5)
	resultPanel = gui:WaitForChild("ResultPanel", 5)
	fadeFrame   = gui:WaitForChild("FadeFrame",   5)
	if resultPanel then
		resultLabel = resultPanel:FindFirstChild("ResultLabel")
	end
	return true
end

function HUDController.Init()
	local ok = waitForGui()
	if not ok then return end

	if topStatus then
		topStatus.Text = (GameConfig.TEST_MODE and "[TEST] " or "") .. "Ожидание..."
	end
	if resultPanel then resultPanel.Visible = false end
	if roundBanner then roundBanner.Visible = false end
	if timerLabel  then timerLabel.Text = "" end
	if fadeFrame   then
		fadeFrame.BackgroundTransparency = 1
		fadeFrame.Visible = false
	end
end

function HUDController.SetStatus(text, color)
	if not topStatus then return end
	topStatus.Text       = (GameConfig.TEST_MODE and "[TEST] " or "") .. (text or "")
	topStatus.TextColor3 = color or Color3.fromRGB(255,255,255)
end

function HUDController.SetTimer(seconds)
	if not timerLabel then return end
	if seconds == nil or seconds < 0 then
		timerLabel.Text    = ""
		timerLabel.Visible = false
		return
	end
	timerLabel.Visible    = true
	local s = math.floor(seconds)
	timerLabel.Text       = string.format("%d:%02d", math.floor(s/60), s%60)
	timerLabel.TextColor3 = (s <= UIConfig.TIMER_WARNING_THRESHOLD)
		and UIConfig.TIMER_WARNING_COLOR
		or  UIConfig.TIMER_NORMAL_COLOR
end

function HUDController.ShowBanner(text, color)
	if not roundBanner then return end
	roundBanner.Text       = text or ""
	roundBanner.TextColor3 = color or Color3.fromRGB(255,220,0)
	roundBanner.TextTransparency = 0
	roundBanner.Visible    = true

	task.delay(UIConfig.BANNER_DISPLAY_TIME, function()
		TweenService:Create(roundBanner,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 1 }
		):Play()
		task.delay(0.4, function()
			roundBanner.Visible = false
		end)
	end)
end

function HUDController.ShowResult(isWinner, isDraw)
	if not resultPanel then return end
	resultPanel.Visible              = true
	resultPanel.BackgroundTransparency = 1

	local txt, col
	if isDraw then
		txt = UIConfig.DRAW_TEXT
		col = Color3.fromRGB(200,200,200)
	elseif isWinner then
		txt = UIConfig.WIN_TEXT
		col = Color3.fromRGB(255,220,0)
	else
		txt = UIConfig.LOSE_TEXT
		col = Color3.fromRGB(200,60,60)
	end

	if resultLabel then
		resultLabel.Text       = txt
		resultLabel.TextColor3 = col
	end

	TweenService:Create(resultPanel,
		TweenInfo.new(UIConfig.RESULT_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.3 }
	):Play()
end

function HUDController.HideResult()
	if not resultPanel then return end
	TweenService:Create(resultPanel,
		TweenInfo.new(UIConfig.PANEL_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
	task.delay(UIConfig.PANEL_TWEEN_TIME, function()
		resultPanel.Visible = false
	end)
end

function HUDController.FadeTo(alpha, duration)
	if not fadeFrame then return end
	alpha    = alpha    or 0
	duration = duration or 0.5
	fadeFrame.Visible = true
	TweenService:Create(fadeFrame,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 - alpha }
	):Play()
	if alpha <= 0 then
		task.delay(duration + 0.05, function()
			if fadeFrame then fadeFrame.Visible = false end
		end)
	end
end

return HUDController