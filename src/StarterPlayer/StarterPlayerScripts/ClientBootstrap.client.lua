-- LocalScript: StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════════
--  REMOTES
-- ══════════════════════════════════════════════════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
assert(Remotes, "[ClientBootstrap] Remotes не найдены!")

local RoundStateRemote   = Remotes:WaitForChild("RoundState")
local HUDMessageRemote   = Remotes:WaitForChild("HUDMessage")
local RoundResultRemote  = Remotes:WaitForChild("RoundResult")
local PlayCelebRemote    = Remotes:WaitForChild("PlayCelebration")
local SyncDarkRemote     = Remotes:WaitForChild("SyncDarkness")
local SubmitChoiceRemote = Remotes:WaitForChild("SubmitChoice")
local CombatInputRemote  = Remotes:WaitForChild("CombatInput")

-- ══════════════════════════════════════════════════════════════
--  КОНФИГИ
-- ══════════════════════════════════════════════════════════════
local Enums       = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local GameConfig  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CombatConfig"))

-- ══════════════════════════════════════════════════════════════
--  КОНСТАНТЫ
-- ══════════════════════════════════════════════════════════════
local PLACEHOLDER_IMAGE = "rbxassetid://112107392394775"
local WARN_THRESHOLD    = 5   -- секунд до конца — таймер краснеет

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		pcall(function() inst[k] = v end)
	end
	if parent then inst.Parent = parent end
	return inst
end

local function tween(inst, props, t, style, dir)
	style = style or Enum.EasingStyle.Quart
	dir   = dir   or Enum.EasingDirection.Out
	TweenService:Create(inst, TweenInfo.new(t, style, dir), props):Play()
end

-- ══════════════════════════════════════════════════════════════
--  СОЗДАЁМ MainHUD
-- ══════════════════════════════════════════════════════════════
local old = playerGui:FindFirstChild("MainHUD")
if old then old:Destroy() end

local mainHUD = make("ScreenGui", {
	Name           = "MainHUD",
	ResetOnSpawn   = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder   = 10,
}, playerGui)

-- ── TOP BAR ──────────────────────────────────────────────────
local topBar = make("Frame", {
	Size                   = UDim2.new(1, 0, 0, 56),
	Position               = UDim2.new(0, 0, 0, 0),
	BackgroundColor3       = Color3.fromRGB(8, 8, 18),
	BackgroundTransparency = 0,
	BorderSizePixel        = 0,
	ZIndex                 = 5,
}, mainHUD)
make("UIGradient", {
	Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 14, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8,  8,  18)),
	}),
	Rotation = 90,
}, topBar)

-- Золотая линия снизу топбара
make("Frame", {
	Size             = UDim2.new(1, 0, 0, 2),
	Position         = UDim2.new(0, 0, 1, -2),
	BackgroundColor3 = Color3.fromRGB(255, 200, 50),
	BackgroundTransparency = 0.3,
	BorderSizePixel  = 0,
	ZIndex           = 6,
}, topBar)

local topStatus = make("TextLabel", {
	Name                   = "TopStatus",
	Size                   = UDim2.new(1, -24, 1, 0),
	Position               = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(240, 235, 255),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "Waiting...",
	TextXAlignment         = Enum.TextXAlignment.Center,
	ZIndex                 = 6,
}, topBar)

-- TEST MODE badge
if GameConfig.TEST_MODE then
	local badge = make("Frame", {
		Size             = UDim2.new(0, 90, 0, 22),
		Position         = UDim2.new(1, -96, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(255, 160, 0),
		BorderSizePixel  = 0,
		ZIndex           = 7,
	}, topBar)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, badge)
	make("TextLabel", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                   = "TEST MODE",
		Font                   = Enum.Font.GothamBold,
		TextScaled             = true,
		TextColor3             = Color3.fromRGB(20, 10, 0),
		ZIndex                 = 8,
	}, badge)
end

-- ── TIMER ────────────────────────────────────────────────────
local timerFrame = make("Frame", {
	Name             = "TimerFrame",
	Size             = UDim2.new(0, 110, 0, 46),
	Position         = UDim2.new(0.5, -55, 0, 60),
	BackgroundColor3 = Color3.fromRGB(10, 8, 25),
	BackgroundTransparency = 0.1,
	BorderSizePixel  = 0,
	ZIndex           = 7,
	Visible          = false,
}, mainHUD)
make("UICorner",  { CornerRadius = UDim.new(0, 12) }, timerFrame)
make("UIStroke",  { Color = Color3.fromRGB(255,200,50), Thickness = 1.5, Transparency = 0.4 }, timerFrame)

local timerLabel = make("TextLabel", {
	Name                   = "TimerLabel",
	Size                   = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 255, 255),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "",
	ZIndex                 = 8,
}, timerFrame)

-- ── ROUND BANNER ─────────────────────────────────────────────
local roundBanner = make("TextLabel", {
	Name                   = "RoundBanner",
	Size                   = UDim2.new(1, 0, 0, 90),
	Position               = UDim2.new(0, 0, 0.28, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 220, 50),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "",
	TextStrokeTransparency = 0,
	TextStrokeColor3       = Color3.fromRGB(0, 0, 0),
	TextTransparency       = 1,
	Visible                = false,
	ZIndex                 = 8,
}, mainHUD)

-- ── RESULT PANEL ─────────────────────────────────────────────
local resultPanel = make("Frame", {
	Name                   = "ResultPanel",
	Size                   = UDim2.new(0, 360, 0, 110),
	Position               = UDim2.new(0.5, -180, 0.35, 0),
	BackgroundColor3       = Color3.fromRGB(10, 8, 25),
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Visible                = false,
	ZIndex                 = 9,
}, mainHUD)
make("UICorner", { CornerRadius = UDim.new(0, 20) }, resultPanel)
make("UIStroke", { Color = Color3.fromRGB(255,220,50), Thickness = 2.5, Transparency = 0.2 }, resultPanel)

local resultLabel = make("TextLabel", {
	Name                   = "ResultLabel",
	Size                   = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 220, 50),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "",
	ZIndex                 = 10,
}, resultPanel)

-- ══════════════════════════════════════════════════════════════
--  CHOICE PANEL
-- ══════════════════════════════════════════════════════════════
--
--  Структура:
--  ┌────────────────────────────────────────────────┐
--  │              A  VS  B  (VS banner)             │
--  │  ┌─────────────────┐   ┌─────────────────┐    │
--  │  │   [  IMAGE  ]   │   │   [  IMAGE  ]   │    │
--  │  │                 │   │                 │    │
--  │  │     NINJA       │   │     PIRATE      │    │
--  │  │   [ CHOOSE ]    │   │   [ CHOOSE ]    │    │
--  │  └─────────────────┘   └─────────────────┘    │
--  └────────────────────────────────────────────────┘

-- Панель стартует за нижним краем экрана
local choicePanel = make("Frame", {
	Name                   = "ChoicePanel",
	Size                   = UDim2.new(1, 0, 0.46, 0),
	Position               = UDim2.new(0, 0, 1.1, 0),
	BackgroundColor3       = Color3.fromRGB(6, 5, 18),
	BackgroundTransparency = 0,
	BorderSizePixel        = 0,
	Visible                = true,
	ZIndex                 = 6,
	ClipsDescendants       = false,
}, mainHUD)
make("UICorner", { CornerRadius = UDim.new(0, 24) }, choicePanel)

-- Верхняя декоративная линия панели
make("Frame", {
	Size             = UDim2.new(1, 0, 0, 3),
	BackgroundColor3 = Color3.fromRGB(255, 200, 50),
	BackgroundTransparency = 0,
	BorderSizePixel  = 0,
	ZIndex           = 7,
}, choicePanel)

make("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 180, 20)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 80)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 180, 20)),
	}),
	Rotation = 0,
}, choicePanel:FindFirstChildOfClass("Frame"))

-- VS Banner
local vsBanner = make("TextLabel", {
	Name                   = "VSBanner",
	Size                   = UDim2.new(1, 0, 0, 36),
	Position               = UDim2.new(0, 0, 0, 8),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 215, 50),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "CHOOSE YOUR SIDE",
	TextStrokeTransparency = 0.5,
	TextStrokeColor3       = Color3.fromRGB(0, 0, 0),
	ZIndex                 = 7,
}, choicePanel)

-- ── Функция карточки ──────────────────────────────────────────
local function makeCard(parent, name, xPos, accentColor)
	local card = make("Frame", {
		Name                   = name,
		Size                   = UDim2.new(0.46, 0, 0.84, 0),
		Position               = UDim2.new(xPos, 0, 0.12, 0),
		BackgroundColor3       = Color3.fromRGB(12, 10, 30),
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ZIndex                 = 7,
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 16) }, card)
	make("UIStroke", {
		Color           = accentColor,
		Thickness       = 2,
		Transparency    = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, card)

	-- Цветная полоска сверху карточки (акцент команды)
	local topStripe = make("Frame", {
		Name             = "TopStripe",
		Size             = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = accentColor,
		BackgroundTransparency = 0,
		BorderSizePixel  = 0,
		ZIndex           = 8,
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0, 16) }, topStripe)

	-- Контейнер картинки (верхние 54%)
	local imgBox = make("Frame", {
		Name                   = "ImageContainer",
		Size                   = UDim2.new(1, -16, 0.54, -10),
		Position               = UDim2.new(0, 8, 0, 14),
		BackgroundColor3       = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel        = 0,
		ZIndex                 = 8,
		ClipsDescendants       = true,
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, imgBox)
	make("UIStroke", {
		Color        = accentColor,
		Thickness    = 1.5,
		Transparency = 0.6,
	}, imgBox)

	-- Картинка
	make("ImageLabel", {
		Name                   = "CardImage",
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image                  = PLACEHOLDER_IMAGE,
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 9,
	}, imgBox)

	-- Название варианта
	local labelBg = make("Frame", {
		Name             = "LabelBg",
		Size             = UDim2.new(1, 0, 0.20, 0),
		Position         = UDim2.new(0, 0, 0.56, 0),
		BackgroundColor3 = accentColor,
		BackgroundTransparency = 0.75,
		BorderSizePixel  = 0,
		ZIndex           = 8,
	}, card)

	make("TextLabel", {
		Name                   = "Label",
		Size                   = UDim2.new(1, -8, 1, 0),
		Position               = UDim2.new(0, 4, 0, 0),
		BackgroundTransparency = 1,
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextScaled             = true,
		Font                   = Enum.Font.GothamBold,
		Text                   = "???",
		TextStrokeTransparency = 0.4,
		TextStrokeColor3       = Color3.fromRGB(0, 0, 0),
		ZIndex                 = 9,
	}, labelBg)

	-- Кнопка CHOOSE
	local btn = make("TextButton", {
		Name                   = "Button",
		Size                   = UDim2.new(0.78, 0, 0.17, 0),
		Position               = UDim2.new(0.11, 0, 0.80, 0),
		BackgroundColor3       = accentColor,
		TextColor3             = Color3.fromRGB(255, 255, 255),
		Font                   = Enum.Font.GothamBold,
		Text                   = "CHOOSE",
		TextScaled             = true,
		BorderSizePixel        = 0,
		AutoButtonColor        = false,
		ZIndex                 = 9,
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, btn)
	make("UIStroke", {
		Color        = Color3.fromRGB(255, 255, 255),
		Thickness    = 1.5,
		Transparency = 0.6,
	}, btn)

	-- Hover/press анимация кнопки
	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundTransparency = 0.2 }, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundTransparency = 0 }, 0.12)
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, { Size = UDim2.new(0.72, 0, 0.15, 0), Position = UDim2.new(0.14, 0, 0.82, 0) }, 0.08)
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, { Size = UDim2.new(0.78, 0, 0.17, 0), Position = UDim2.new(0.11, 0, 0.80, 0) }, 0.12)
	end)

	return card
end

local leftCard  = makeCard(choicePanel, "LeftCard",  0.02, Color3.fromRGB(60, 140, 255))
local rightCard = makeCard(choicePanel, "RightCard", 0.52, Color3.fromRGB(255, 90,  40))

choicePanel.Visible = false

print("[ClientBootstrap] MainHUD создан.")

-- ══════════════════════════════════════════════════════════════
--  HUD FUNCTIONS
-- ══════════════════════════════════════════════════════════════
local HUD = {}

function HUD.SetStatus(text, color)
	topStatus.Text       = text or ""
	topStatus.TextColor3 = color or Color3.fromRGB(240, 235, 255)
end

function HUD.SetTimer(seconds)
	if seconds == nil or seconds < 0 then
		tween(timerFrame, { BackgroundTransparency = 1 }, 0.2)
		task.delay(0.2, function() timerFrame.Visible = false end)
		return
	end
	timerFrame.Visible = true
	timerFrame.BackgroundTransparency = 0.1
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	timerLabel.Text = string.format("%d:%02d", m, s)

	if seconds <= WARN_THRESHOLD then
		timerLabel.TextColor3 = Color3.fromRGB(255, 80, 60)
		-- Пульс
		tween(timerFrame, { Size = UDim2.new(0, 122, 0, 52) }, 0.1, Enum.EasingStyle.Bounce)
		task.delay(0.15, function()
			tween(timerFrame, { Size = UDim2.new(0, 110, 0, 46) }, 0.1)
		end)
	else
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

function HUD.ShowBanner(text, color, duration)
	roundBanner.Text             = text or ""
	roundBanner.TextColor3       = color or Color3.fromRGB(255, 220, 50)
	roundBanner.TextTransparency = 1
	roundBanner.Size             = UDim2.new(1, 0, 0, 70)
	roundBanner.Visible          = true

	-- Появление + увеличение
	tween(roundBanner, { TextTransparency = 0, Size = UDim2.new(1, 0, 0, 90) }, 0.25,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	task.delay(duration or 2.5, function()
		tween(roundBanner, { TextTransparency = 1, Size = UDim2.new(1, 0, 0, 70) }, 0.3)
		task.delay(0.3, function() roundBanner.Visible = false end)
	end)
end

function HUD.ShowResult(isWinner, isDraw)
	local text, color, strokeColor
	if isDraw then
		text        = "DRAW"
		color       = Color3.fromRGB(200, 200, 200)
		strokeColor = Color3.fromRGB(150, 150, 150)
	elseif isWinner then
		text        = "VICTORY!"
		color       = Color3.fromRGB(255, 215, 50)
		strokeColor = Color3.fromRGB(255, 150, 0)
	else
		text        = "DEFEATED"
		color       = Color3.fromRGB(220, 70, 70)
		strokeColor = Color3.fromRGB(140, 20, 20)
	end

	resultLabel.Text             = text
	resultLabel.TextColor3       = color
	resultLabel.TextStrokeColor3 = strokeColor
	resultLabel.TextStrokeTransparency = 0.3

	resultPanel.BackgroundTransparency = 1
	resultPanel.Size     = UDim2.new(0, 300, 0, 90)
	resultPanel.Position = UDim2.new(0.5, -150, 0.32, 0)
	resultPanel.Visible  = true

	tween(resultPanel, {
		BackgroundTransparency = 0.08,
		Size     = UDim2.new(0, 380, 0, 114),
		Position = UDim2.new(0.5, -190, 0.35, 0),
	}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function HUD.HideResult()
	tween(resultPanel, { BackgroundTransparency = 1 }, 0.3)
	task.delay(0.3, function() resultPanel.Visible = false end)
end

-- ══════════════════════════════════════════════════════════════
--  CHOICE FUNCTIONS
-- ══════════════════════════════════════════════════════════════
local choiceEnabled = false
local currentSide   = nil

local function getCardParts(card)
	local imgBox   = card:FindFirstChild("ImageContainer")
	local img      = imgBox  and imgBox:FindFirstChild("CardImage")
	local labelBg  = card:FindFirstChild("LabelBg")
	local label    = labelBg and labelBg:FindFirstChild("Label")
	local btn      = card:FindFirstChild("Button")
	local stripe   = card:FindFirstChild("TopStripe")
	return img, label, btn, stripe
end

local function setCardContent(card, text, color, imageId)
	if not card then return end
	local img, label, btn, stripe = getCardParts(card)

	-- Обновляем акцент-цвет
	if stripe then stripe.BackgroundColor3 = color end
	if btn    then btn.BackgroundColor3    = color end

	-- Текст
	if label then label.Text = text or "???" end

	-- Картинка: если 0 или nil — используем placeholder
	if img then
		if imageId and imageId ~= 0 then
			img.Image = "rbxassetid://" .. tostring(imageId)
		else
			img.Image = PLACEHOLDER_IMAGE
		end
	end

	card.Visible = true
	card.BackgroundTransparency = 0
end

local function resetCardHighlight(card, accentColor)
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color       = accentColor
		stroke.Thickness   = 2
		stroke.Transparency = 0.5
	end
	tween(card, { BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(12, 10, 30) }, 0.2)
end

local function highlightSelected(side)
	local leftAccent  = Color3.fromRGB(60,  140, 255)
	local rightAccent = Color3.fromRGB(255,  90,  40)
	local dim         = 0.55

	if side == Enums.Team.Left then
		-- Left: яркая рамка
		local s = leftCard:FindFirstChildOfClass("UIStroke")
		if s then s.Color = Color3.fromRGB(255,215,50); s.Thickness = 4; s.Transparency = 0 end
		tween(leftCard,  { BackgroundTransparency = 0 }, 0.15)
		-- Right: потускнеть
		local sr = rightCard:FindFirstChildOfClass("UIStroke")
		if sr then sr.Transparency = 0.8 end
		tween(rightCard, { BackgroundTransparency = dim }, 0.15)
	else
		-- Right: яркая рамка
		local s = rightCard:FindFirstChildOfClass("UIStroke")
		if s then s.Color = Color3.fromRGB(255,215,50); s.Thickness = 4; s.Transparency = 0 end
		tween(rightCard, { BackgroundTransparency = 0 }, 0.15)
		-- Left: потускнеть
		local sl = leftCard:FindFirstChildOfClass("UIStroke")
		if sl then sl.Transparency = 0.8 end
		tween(leftCard,  { BackgroundTransparency = dim }, 0.15)
	end
end

-- Слайд-анимация панели
local function slidePanel(show)
	choicePanel.Visible = true
	local target = show
		and UDim2.new(0, 0, 0.54, 0)
		or  UDim2.new(0, 0, 1.1,  0)
	tween(choicePanel, { Position = target }, 0.45,
		Enum.EasingStyle.Back,
		show and Enum.EasingDirection.Out or Enum.EasingDirection.In)
	if not show then
		task.delay(0.5, function()
			choicePanel.Visible = false
		end)
	end
end

-- Анимация появления одной карточки
local function animateCardIn(card, delay)
	card.Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset,
		card.Position.Y.Scale + 0.08, card.Position.Y.Offset)
	card.BackgroundTransparency = 1
	task.delay(delay, function()
		tween(card, {
			Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset,
				card.Position.Y.Scale - 0.08, card.Position.Y.Offset),
			BackgroundTransparency = 0,
		}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
end

local function submitChoice(side)
	if not choiceEnabled then return end
	currentSide = side
	highlightSelected(side)
	SubmitChoiceRemote:FireServer({ Side = side })
end

-- Подключаем кнопки
local lBtn = leftCard:FindFirstChild("Button")
local rBtn = rightCard:FindFirstChild("Button")
if lBtn then lBtn.MouseButton1Click:Connect(function() submitChoice(Enums.Team.Left)  end) end
if rBtn then rBtn.MouseButton1Click:Connect(function() submitChoice(Enums.Team.Right) end) end

local Choice = {}

function Choice.RevealA(text, color, imageId)
	choiceEnabled = false
	currentSide   = nil
	rightCard.Visible = false
	setCardContent(leftCard, text, color, imageId)
	if vsBanner then vsBanner.Text = text or "???" end
	slidePanel(true)
	animateCardIn(leftCard, 0.1)
end

function Choice.RevealB(text, color, imageId)
	setCardContent(rightCard, text, color, imageId)
	rightCard.Visible = true
	animateCardIn(rightCard, 0.05)
	local lLabel = leftCard:FindFirstChild("LabelBg") and leftCard.LabelBg:FindFirstChild("Label")
	local lt = lLabel and lLabel.Text or "???"
	if vsBanner then
		vsBanner.Text = lt .. "  VS  " .. (text or "???")
	end
end

function Choice.ShowFull(data)
	choiceEnabled = true
	currentSide   = nil

	setCardContent(leftCard,  data.LeftText,  data.LeftColor,  data.LeftImage)
	setCardContent(rightCard, data.RightText, data.RightColor, data.RightImage)
	resetCardHighlight(leftCard,  Color3.fromRGB(60, 140, 255))
	resetCardHighlight(rightCard, Color3.fromRGB(255, 90,  40))
	leftCard.Visible  = true
	rightCard.Visible = true

	if vsBanner then
		vsBanner.Text = (data.LeftText or "?") .. "  VS  " .. (data.RightText or "?")
	end
	slidePanel(true)
end

function Choice.Hide()
	choiceEnabled = false
	currentSide   = nil
	slidePanel(false)
end

-- ══════════════════════════════════════════════════════════════
--  COMBAT
-- ══════════════════════════════════════════════════════════════
local combatActive = false
local lastAttack   = 0
local lastDash     = 0
local lastBlock    = 0

local function findClosestEnemy()
	local char = localPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local bestDist, bestPlayer = CombatConfig.ATTACK_RANGE, nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p == localPlayer then continue end
		local oc = p.Character
		if not oc then continue end
		local oh = oc:FindFirstChild("HumanoidRootPart")
		if not oh then continue end
		local d = (hrp.Position - oh.Position).Magnitude
		if d < bestDist then bestDist = d; bestPlayer = p end
	end
	return bestPlayer
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe or not combatActive then return end
	local now = tick()
	if input.KeyCode == Enum.KeyCode.F
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if now - lastAttack < CombatConfig.ATTACK_COOLDOWN then return end
		lastAttack = now
		local target = findClosestEnemy()
		if target then
			CombatInputRemote:FireServer({
				Action   = Enums.CombatAction.Melee,
				TargetId = target.UserId,
			})
		end
	elseif input.KeyCode == Enum.KeyCode.Q then
		if now - lastDash < CombatConfig.DASH_COOLDOWN then return end
		lastDash = now
		CombatInputRemote:FireServer({ Action = Enums.CombatAction.Dash })
	elseif input.KeyCode == Enum.KeyCode.E then
		if now - lastBlock < CombatConfig.BLOCK_COOLDOWN then return end
		lastBlock = now
		CombatInputRemote:FireServer({ Action = Enums.CombatAction.Block })
	end
end)

local function setCombatActive(val) combatActive = val end

print("[CombatController] Initialized. Keys: F/Click=Attack, Q=Dash, E=Block")

-- ══════════════════════════════════════════════════════════════
--  CELEBRATION
-- ══════════════════════════════════════════════════════════════
local function playCelebAnim(animId)
	if not animId or animId == 0 then return end
	local char = localPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animId)
	local track = hum:LoadAnimation(anim)
	if track then
		track:Play()
		task.delay(math.max(track.Length, 0.1) + 0.1, function()
			if track.IsPlaying then track:Stop() end
		end)
	end
end

local function playCelebSound(sfxId)
	if not sfxId or sfxId == 0 then return end
	local char = localPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local snd = Instance.new("Sound")
	snd.SoundId = "rbxassetid://" .. tostring(sfxId)
	snd.Volume  = 0.8
	snd.Parent  = hrp
	snd:Play()
	snd.Ended:Connect(function() snd:Destroy() end)
end

-- ══════════════════════════════════════════════════════════════
--  REMOTE LISTENERS
-- ══════════════════════════════════════════════════════════════

RoundStateRemote.OnClientEvent:Connect(function(data)
	if not data then return end
	local phase = data.Phase

	-- Только таймер
	if data.Timer ~= nil and phase ~= nil then
		HUD.SetTimer(data.Timer)
		if phase == Enums.Phase.DarkChoice or
		   phase == Enums.Phase.Battle     or
		   phase == Enums.Phase.Intermission then
			if data.Phase == phase and data.Data == nil then return end
		end
	end

	if phase == Enums.Phase.Intermission then
		HUD.SetStatus("Ожидание игроков...", Color3.fromRGB(180, 180, 200))
		HUD.HideResult()
		Choice.Hide()
		setCombatActive(false)

	elseif phase == Enums.Phase.TeleportToPreArena then
		HUD.SetStatus("На арену!", Color3.fromRGB(100, 200, 255))
		HUD.SetTimer(nil)
		Choice.Hide()

	elseif phase == Enums.Phase.RevealChoiceA then
		HUD.SetStatus("Вариант A:", Color3.fromRGB(160, 200, 255))
		local d = data.Data
		if d then Choice.RevealA(d.Text, d.Color, d.Image) end

	elseif phase == Enums.Phase.RevealChoiceB then
		HUD.SetStatus("Вариант B:", Color3.fromRGB(255, 180, 140))
		local d = data.Data
		if d then Choice.RevealB(d.Text, d.Color, d.Image) end

	elseif phase == Enums.Phase.DarkChoice then
		HUD.SetStatus("Выбери сторону!", Color3.fromRGB(255, 230, 80))
		local d = data.Data
		if d then
			Choice.ShowFull(d)
			HUD.SetTimer(d.Duration)
		end

	elseif phase == Enums.Phase.LockChoice then
		HUD.SetStatus("Выбор зафиксирован!", Color3.fromRGB(180, 255, 180))
		HUD.SetTimer(nil)

	elseif phase == Enums.Phase.AssignTeams then
		HUD.SetStatus("Команды формируются...", Color3.fromRGB(140, 255, 160))
		Choice.Hide()

	elseif phase == Enums.Phase.TeleportToBattle then
		HUD.SetStatus("На позиции!", Color3.fromRGB(255, 160, 60))

	elseif phase == Enums.Phase.Battle then
		setCombatActive(true)
		HUD.SetStatus("БОЙ!", Color3.fromRGB(255, 70, 70))
		local d = data.Data
		if d and d.Duration then HUD.SetTimer(d.Duration) end

	elseif phase == Enums.Phase.Victory then
		setCombatActive(false)
		HUD.SetTimer(nil)
		local d = data.Data
		if d and d.Winner then
			local txt = d.Winner == "Draw"
				and "НИЧЬЯ!"
				or "Победила команда " .. d.Winner .. "!"
			HUD.ShowBanner(txt, Color3.fromRGB(255, 215, 50))
		end

	elseif phase == Enums.Phase.Celebration then
		HUD.SetStatus("Победа!", Color3.fromRGB(255, 215, 50))

	elseif phase == Enums.Phase.ReturnToLobby then
		HUD.SetStatus("Возвращаемся...", Color3.fromRGB(160, 160, 255))
		HUD.SetTimer(nil)

	elseif phase == Enums.Phase.Cleanup then
		HUD.SetStatus("Раунд завершён.", Color3.fromRGB(160, 160, 180))
		Choice.Hide()
		setCombatActive(false)
	end
end)

HUDMessageRemote.OnClientEvent:Connect(function(data)
	if data and data.Message then
		HUD.SetStatus(data.Message, data.Color)
	end
end)

RoundResultRemote.OnClientEvent:Connect(function(data)
	if data then HUD.ShowResult(data.IsWinner, data.IsDraw) end
end)

PlayCelebRemote.OnClientEvent:Connect(function(data)
	if data then
		playCelebAnim(data.AnimId)
		playCelebSound(data.SfxId)
	end
end)

-- SyncDarkness теперь ничего не делает (затемнение убрано)
SyncDarkRemote.OnClientEvent:Connect(function(_) end)

print("[ClientBootstrap] Готов,", localPlayer.Name)