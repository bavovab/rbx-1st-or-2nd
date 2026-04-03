-- ModuleScript
-- Управляет панелью голосования: анимации въезда/выезда, выбор, свернуть/развернуть, таймер.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("UIConfig"))
local Enums      = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local SubmitChoice = Remotes:WaitForChild("SubmitChoice")

local ChoiceController = {}

-- ── refs ──
local playerGui, mainHUD
local choicePanel, leftCard, rightCard
local leftBtn, rightBtn, collapseBtn
local voteTimerFrame, voteTimerLabel
local miniPanel, miniLabel, miniTimer
local leftBorder, rightBorder

local currentSide    = nil
local choiceEnabled  = false
local isCollapsed    = false
local timerThread    = nil

-- Позиции панели
local POS_HIDDEN    = UDim2.new(0, 0, 1, 0)          -- за нижним краем
local POS_VISIBLE   = UDim2.new(0, 0, 0.58, 0)       -- видима

local TWEEN_IN  = TweenInfo.new(0.55, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
local TWEEN_SEL = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TWEEN_TIM = TweenInfo.new(0.25, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

local COLOR_SELECTED   = Color3.fromRGB(255, 220, 0)
local COLOR_UNSELECTED = Color3.fromRGB(80,  80,  80)
local COLOR_DIM        = Color3.fromRGB(40,  40,  40)

local function getRef()
	playerGui  = Players.LocalPlayer:WaitForChild("PlayerGui")
	mainHUD    = playerGui:WaitForChild("MainHUD")
	choicePanel = mainHUD:WaitForChild("ChoicePanel")
	leftCard    = choicePanel:WaitForChild("LeftCard")
	rightCard   = choicePanel:WaitForChild("RightCard")
	leftBtn     = leftCard:WaitForChild("Button")
	rightBtn    = rightCard:WaitForChild("Button")
	collapseBtn = choicePanel:WaitForChild("CollapseBtn")
	voteTimerFrame = choicePanel:WaitForChild("VoteTimerFrame")
	voteTimerLabel = voteTimerFrame:WaitForChild("VoteTimer")
	miniPanel   = mainHUD:WaitForChild("MiniPanel")
	miniLabel   = miniPanel:WaitForChild("MiniLabel")
	miniTimer   = miniPanel:WaitForChild("MiniTimer")
	leftBorder  = leftCard:FindFirstChildOfClass("UIStroke")
	rightBorder = rightCard:FindFirstChildOfClass("UIStroke")
end

-- ── helpers ──
local function setLeftText(text)
	-- пытаемся разделить эмодзи и имя (первое слово — эмодзи)
	local emoji, name = text:match("^(%S+)%s+(.+)$")
	if emoji and name then
		leftCard:FindFirstChild("Emoji").Text = emoji
		leftCard:FindFirstChild("Label").Text = name
	else
		leftCard:FindFirstChild("Emoji").Text = ""
		leftCard:FindFirstChild("Label").Text = text
	end
end

local function setRightText(text)
	local emoji, name = text:match("^(%S+)%s+(.+)$")
	if emoji and name then
		rightCard:FindFirstChild("Emoji").Text = emoji
		rightCard:FindFirstChild("Label").Text = name
	else
		rightCard:FindFirstChild("Emoji").Text = ""
		rightCard:FindFirstChild("Label").Text = text
	end
end

local function highlightSide(side)
	if not leftBorder or not rightBorder then return end
	if side == Enums.Team.Left then
		TweenService:Create(leftBorder,  TWEEN_SEL, { Color = COLOR_SELECTED,   Thickness = 5 }):Play()
		TweenService:Create(rightBorder, TWEEN_SEL, { Color = COLOR_DIM,        Thickness = 2 }):Play()
		TweenService:Create(rightCard, TWEEN_SEL, { BackgroundTransparency = 0.45 }):Play()
		TweenService:Create(leftCard,  TWEEN_SEL, { BackgroundTransparency = 0.0  }):Play()
	elseif side == Enums.Team.Right then
		TweenService:Create(rightBorder, TWEEN_SEL, { Color = COLOR_SELECTED,   Thickness = 5 }):Play()
		TweenService:Create(leftBorder,  TWEEN_SEL, { Color = COLOR_DIM,        Thickness = 2 }):Play()
		TweenService:Create(leftCard,  TWEEN_SEL, { BackgroundTransparency = 0.45 }):Play()
		TweenService:Create(rightCard, TWEEN_SEL, { BackgroundTransparency = 0.0  }):Play()
	else
		TweenService:Create(leftBorder,  TWEEN_SEL, { Color = COLOR_UNSELECTED, Thickness = 3 }):Play()
		TweenService:Create(rightBorder, TWEEN_SEL, { Color = COLOR_UNSELECTED, Thickness = 3 }):Play()
		TweenService:Create(leftCard,  TWEEN_SEL, { BackgroundTransparency = 0.05 }):Play()
		TweenService:Create(rightCard, TWEEN_SEL, { BackgroundTransparency = 0.05 }):Play()
	end
end

local function updateMiniLabel(side)
	if side == Enums.Team.Left then
		miniLabel.Text = "✅ " .. (leftCard:FindFirstChild("Label") and leftCard.Label.Text or "Левый")
		miniLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	elseif side == Enums.Team.Right then
		miniLabel.Text = "✅ " .. (rightCard:FindFirstChild("Label") and rightCard.Label.Text or "Правый")
		miniLabel.TextColor3 = Color3.fromRGB(255, 140, 80)
	else
		miniLabel.Text = "⏳ Не выбрано"
		miniLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end

-- ── анимация въезда панели ──
local function slideIn()
	isCollapsed = false
	choicePanel.Position = POS_HIDDEN
	choicePanel.Visible  = true
	miniPanel.Visible    = false
	collapseBtn.Text     = "▼"
	TweenService:Create(choicePanel, TWEEN_IN, { Position = POS_VISIBLE }):Play()
end

-- ── анимация выезда панели ──
local function slideOut(callback)
	TweenService:Create(choicePanel, TWEEN_OUT, { Position = POS_HIDDEN }):Play()
	task.delay(0.36, function()
		choicePanel.Visible = false
		if callback then callback() end
	end)
end

-- ── свернуть ──
local function collapse()
	if isCollapsed then return end
	isCollapsed = true
	collapseBtn.Text = "▲"
	updateMiniLabel(currentSide)
	TweenService:Create(choicePanel, TWEEN_OUT, { Position = POS_HIDDEN }):Play()
	task.delay(0.2, function()
		miniPanel.Visible = true
		TweenService:Create(miniPanel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, -110, 1, -54) }):Play()
	end)
end

-- ── развернуть ──
local function expand()
	if not isCollapsed then return end
	isCollapsed = false
	collapseBtn.Text = "▼"
	miniPanel.Visible = false
	choicePanel.Position = POS_HIDDEN
	choicePanel.Visible  = true
	TweenService:Create(choicePanel, TWEEN_IN, { Position = POS_VISIBLE }):Play()
end

-- ── таймер голосования ──
local function startVoteTimer(seconds)
	if timerThread then
		task.cancel(timerThread)
		timerThread = nil
	end
	voteTimerFrame.Visible = true
	voteTimerLabel.Text    = tostring(seconds)
	miniTimer.Text         = tostring(seconds)

	timerThread = task.spawn(function()
		for i = seconds, 0, -1 do
			voteTimerLabel.Text = tostring(i)
			miniTimer.Text      = tostring(i)
			-- пульс при <= 5
			if i <= 5 then
				voteTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				miniTimer.TextColor3     = Color3.fromRGB(255, 80, 80)
				TweenService:Create(voteTimerLabel,
					TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextSize = 28 }):Play()
				task.wait(0.12)
				TweenService:Create(voteTimerLabel,
					TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ TextSize = 22 }):Play()
			else
				voteTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
				miniTimer.TextColor3     = Color3.fromRGB(255, 255, 100)
			end
			if i > 0 then task.wait(1) end
		end
		voteTimerFrame.Visible = false
	end)
end

local function stopVoteTimer()
	if timerThread then
		task.cancel(timerThread)
		timerThread = nil
	end
	voteTimerFrame.Visible = false
end

-- ── выбор ──
local function selectSide(side)
	if not choiceEnabled then return end
	currentSide = side
	SubmitChoice:FireServer({ Side = side })
	highlightSide(side)
	updateMiniLabel(side)

	-- анимация кнопки
	local btn = (side == Enums.Team.Left) and leftBtn or rightBtn
	local origSize = btn.Size
	TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Size = origSize - UDim2.new(0.05, 0, 0.05, 0) }):Play()
	task.delay(0.08, function()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize }):Play()
	end)
end

-- ══════════════════════════════════════════
--  PUBLIC API
-- ══════════════════════════════════════════

function ChoiceController.Init()
	getRef()

	-- Кнопки выбора
	leftBtn.MouseButton1Click:Connect(function()
		selectSide(Enums.Team.Left)
	end)
	rightBtn.MouseButton1Click:Connect(function()
		selectSide(Enums.Team.Right)
	end)

	-- Кнопка свернуть/развернуть
	collapseBtn.MouseButton1Click:Connect(function()
		if isCollapsed then expand() else collapse() end
	end)

	-- Клик по мини-панели разворачивает
	miniPanel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			expand()
		end
	end)

	choicePanel.Visible = false
	miniPanel.Visible   = false
end

-- Показать только левую карту (RevealA)
function ChoiceController.RevealChoiceA(text, color)
	setLeftText(text)
	leftCard.BackgroundColor3 = color
	leftCard:FindFirstChildOfClass("UIGradient"):Destroy()  -- убираем градиент для чистоты reveal
	rightCard:FindFirstChild("Emoji").Text  = "?"
	rightCard:FindFirstChild("Label").Text  = "???"
	highlightSide(nil)
	choiceEnabled = false
	slideIn()
	-- правую карту скрываем визуально (прозрачность)
	rightCard.BackgroundTransparency = 0.75
	rightBtn.BackgroundTransparency  = 0.85
end

-- Показать правую карту (RevealB)
function ChoiceController.RevealChoiceB(text, color)
	setRightText(text)
	rightCard.BackgroundColor3       = color
	rightCard.BackgroundTransparency = 0.05
	rightBtn.BackgroundTransparency  = 0.1
	-- маленькая анимация «появления»
	rightCard.Size = UDim2.new(0.36, 0, 0.88, 0)
	TweenService:Create(rightCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0.46, 0, 0.88, 0) }):Play()
end

-- Полная панель с таймером (DarkChoice)
function ChoiceController.ShowFullChoices(data)
	choiceEnabled = true
	currentSide   = nil
	isCollapsed   = false
	collapseBtn.Text = "▼"

	if data.LeftText  then setLeftText(data.LeftText)   end
	if data.RightText then setRightText(data.RightText) end
	if data.LeftColor  then leftCard.BackgroundColor3  = data.LeftColor  end
	if data.RightColor then rightCard.BackgroundColor3 = data.RightColor end

	leftCard.BackgroundTransparency  = 0.05
	rightCard.BackgroundTransparency = 0.05
	leftBtn.BackgroundTransparency   = 0.1
	rightBtn.BackgroundTransparency  = 0.1
	highlightSide(nil)

	-- Убедимся что панель видна
	if not choicePanel.Visible or choicePanel.Position == POS_HIDDEN then
		slideIn()
	end

	if data.Duration then
		startVoteTimer(data.Duration)
	end

	voteTimerFrame.Visible = data.Duration ~= nil
	miniPanel.Visible      = false
end

function ChoiceController.HideChoices()
	choiceEnabled = false
	currentSide   = nil
	stopVoteTimer()
	if choicePanel.Visible then
		slideOut()
	end
	miniPanel.Visible = false
end

-- Обновить таймер из сети (каждую секунду из RoundService)
function ChoiceController.UpdateTimer(seconds)
	if not voteTimerFrame then return end
	voteTimerLabel.Text = tostring(math.max(0, seconds))
	miniTimer.Text      = tostring(math.max(0, seconds))
	if seconds <= 5 then
		voteTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		miniTimer.TextColor3     = Color3.fromRGB(255, 80, 80)
	end
end

return ChoiceController