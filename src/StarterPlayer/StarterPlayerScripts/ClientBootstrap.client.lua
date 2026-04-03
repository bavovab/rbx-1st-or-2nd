-- LocalScript: StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua
-- HUD создаётся здесь же, синхронно, до подключения любых remote listeners.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════════
--  СОЗДАНИЕ MainHUD (синхронно, самое первое действие)
-- ══════════════════════════════════════════════════════════════

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		pcall(function() inst[k] = v end)
	end
	if parent then inst.Parent = parent end
	return inst
end

-- Удаляем старый если есть
local oldHUD = playerGui:FindFirstChild("MainHUD")
if oldHUD then oldHUD:Destroy() end

local mainHUD = make("ScreenGui", {
	Name           = "MainHUD",
	ResetOnSpawn   = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder   = 10,
}, playerGui)

-- ── Top Bar ──
local topBar = make("Frame", {
	Name                   = "TopBar",
	Size                   = UDim2.new(1, 0, 0, 44),
	Position               = UDim2.new(0, 0, 0, 0),
	BackgroundColor3       = Color3.fromRGB(10, 10, 20),
	BackgroundTransparency = 0.35,
	BorderSizePixel        = 0,
	ZIndex                 = 5,
}, mainHUD)

make("TextLabel", {
	Name                   = "TopStatus",
	Size                   = UDim2.new(1, -20, 1, 0),
	Position               = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 255, 255),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "⏳ Ожидание...",
	TextXAlignment         = Enum.TextXAlignment.Left,
	ZIndex                 = 6,
}, topBar)

-- ── Timer ──
make("TextLabel", {
	Name                   = "TimerLabel",
	Size                   = UDim2.new(0, 100, 0, 44),
	Position               = UDim2.new(0.5, -50, 0, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 255, 255),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "",
	ZIndex                 = 7,
}, mainHUD)

-- ── Round Banner ──
make("TextLabel", {
	Name                   = "RoundBanner",
	Size                   = UDim2.new(0.8, 0, 0, 70),
	Position               = UDim2.new(0.1, 0, 0.32, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 220, 0),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "",
	TextStrokeTransparency = 0.4,
	TextStrokeColor3       = Color3.fromRGB(0, 0, 0),
	Visible                = false,
	ZIndex                 = 8,
}, mainHUD)

-- ── Result Panel ──
local resultPanel = make("Frame", {
	Name                   = "ResultPanel",
	Size                   = UDim2.new(0.44, 0, 0.18, 0),
	Position               = UDim2.new(0.28, 0, 0.40, 0),
	BackgroundColor3       = Color3.fromRGB(10, 10, 20),
	BackgroundTransparency = 0.25,
	BorderSizePixel        = 0,
	Visible                = false,
	ZIndex                 = 9,
}, mainHUD)
make("UICorner",  { CornerRadius = UDim.new(0, 18) }, resultPanel)
make("UIStroke",  { Color = Color3.fromRGB(255, 220, 0), Thickness = 2, Transparency = 0.3 }, resultPanel)
make("TextLabel", {
	Name                   = "ResultLabel",
	Size                   = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	TextColor3             = Color3.fromRGB(255, 220, 0),
	TextScaled             = true,
	Font                   = Enum.Font.GothamBold,
	Text                   = "",
	ZIndex                 = 10,
}, resultPanel)

-- ── Choice Panel ──
local choicePanel = make("Frame", {
	Name                   = "ChoicePanel",
	Size                   = UDim2.new(1, 0, 0.42, 0),
	Position               = UDim2.new(0, 0, 1, 0),   -- скрыт за нижним краем
	BackgroundTransparency = 1,
	Visible                = true,
	ZIndex                 = 6,
	ClipsDescendants       = false,
}, mainHUD)

-- Кнопка свернуть
local collapseBtn = make("TextButton", {
	Name                   = "CollapseBtn",
	Size                   = UDim2.new(0, 36, 0, 36),
	Position               = UDim2.new(0.5, -18, 0, -40),
	BackgroundColor3       = Color3.fromRGB(30, 30, 50),
	BackgroundTransparency = 0.2,
	TextColor3             = Color3.fromRGB(255, 255, 255),
	Text                   = "▼",
	Font                   = Enum.Font.GothamBold,
	TextScaled             = true,
	ZIndex                 = 10,
	BorderSizePixel        = 0,
}, choicePanel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, collapseBtn)

-- Left Card
local leftCard = make("Frame", {
	Name                   = "LeftCard",
	Size                   = UDim2.new(0.46, 0, 0.88, 0),
	Position               = UDim2.new(0.02, 0, 0.06, 0),
	BackgroundColor3       = Color3.fromRGB(20, 80, 200),
	BackgroundTransparency = 0.05,
	BorderSizePixel        = 0,
	ZIndex                 = 7,
}, choicePanel)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, leftCard)
make("UIStroke", { Name = "Border", Color = Color3.fromRGB(80,80,80), Thickness = 3 }, leftCard)
make("UIGradient", {
	Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10,  50, 160)),
	}),
	Rotation = 135,
}, leftCard)
make("TextLabel", { Name="Emoji",  Size=UDim2.new(1,0,0.38,0), Position=UDim2.new(0,0,0.04,0), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextScaled=true, Font=Enum.Font.GothamBold, Text="?",      ZIndex=8 }, leftCard)
make("TextLabel", { Name="Label",  Size=UDim2.new(1,-10,0.28,0), Position=UDim2.new(0,5,0.42,0), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextScaled=true, Font=Enum.Font.GothamBold, Text="Левый", ZIndex=8 }, leftCard)
make("TextLabel", { Name="VoteCount", Size=UDim2.new(1,0,0.16,0), Position=UDim2.new(0,0,0.72,0), BackgroundTransparency=1, TextColor3=Color3.fromRGB(200,230,255), TextScaled=true, Font=Enum.Font.Gotham, Text="", ZIndex=8 }, leftCard)
local leftBtn = make("TextButton", {
	Name="Button", Size=UDim2.new(0.7,0,0.22,0), Position=UDim2.new(0.15,0,0.75,0),
	BackgroundColor3=Color3.new(1,1,1), BackgroundTransparency=0.1,
	TextColor3=Color3.fromRGB(20,60,180), Font=Enum.Font.GothamBold,
	Text="Выбрать", TextScaled=true, ZIndex=9, BorderSizePixel=0,
}, leftCard)
make("UICorner", { CornerRadius=UDim.new(0,10) }, leftBtn)

-- Right Card
local rightCard = make("Frame", {
	Name                   = "RightCard",
	Size                   = UDim2.new(0.46, 0, 0.88, 0),
	Position               = UDim2.new(0.52, 0, 0.06, 0),
	BackgroundColor3       = Color3.fromRGB(180, 50, 10),
	BackgroundTransparency = 0.05,
	BorderSizePixel        = 0,
	ZIndex                 = 7,
}, choicePanel)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, rightCard)
make("UIStroke", { Name = "Border", Color = Color3.fromRGB(80,80,80), Thickness = 3 }, rightCard)
make("UIGradient", {
	Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80,  20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 30,   0)),
	}),
	Rotation = 135,
}, rightCard)
make("TextLabel", { Name="Emoji",  Size=UDim2.new(1,0,0.38,0), Position=UDim2.new(0,0,0.04,0), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextScaled=true, Font=Enum.Font.GothamBold, Text="?",       ZIndex=8 }, rightCard)
make("TextLabel", { Name="Label",  Size=UDim2.new(1,-10,0.28,0), Position=UDim2.new(0,5,0.42,0), BackgroundTransparency=1, TextColor3=Color3.new(1,1,1), TextScaled=true, Font=Enum.Font.GothamBold, Text="Правый", ZIndex=8 }, rightCard)
make("TextLabel", { Name="VoteCount", Size=UDim2.new(1,0,0.16,0), Position=UDim2.new(0,0,0.72,0), BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,200,180), TextScaled=true, Font=Enum.Font.Gotham, Text="", ZIndex=8 }, rightCard)
local rightBtn = make("TextButton", {
	Name="Button", Size=UDim2.new(0.7,0,0.22,0), Position=UDim2.new(0.15,0,0.75,0),
	BackgroundColor3=Color3.new(1,1,1), BackgroundTransparency=0.1,
	TextColor3=Color3.fromRGB(160,40,0), Font=Enum.Font.GothamBold,
	Text="Выбрать", TextScaled=true, ZIndex=9, BorderSizePixel=0,
}, rightCard)
make("UICorner", { CornerRadius=UDim.new(0,10) }, rightBtn)

-- Vote Timer Frame (внутри choicePanel)
local voteTimerFrame = make("Frame", {
	Name                   = "VoteTimerFrame",
	Size                   = UDim2.new(0.3, 0, 0, 34),
	Position               = UDim2.new(0.35, 0, 0, -38),
	BackgroundColor3       = Color3.fromRGB(10, 10, 20),
	BackgroundTransparency = 0.2,
	BorderSizePixel        = 0,
	ZIndex                 = 10,
	Visible                = false,
}, choicePanel)
make("UICorner", { CornerRadius=UDim.new(0,8) }, voteTimerFrame)
local voteTimerLabel = make("TextLabel", {
	Name="VoteTimer", Size=UDim2.new(1,0,1,0),
	BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,100),
	TextScaled=true, Font=Enum.Font.GothamBold, Text="10", ZIndex=11,
}, voteTimerFrame)

-- Mini Panel (свёрнутое состояние — живёт в mainHUD)
local miniPanel = make("Frame", {
	Name                   = "MiniPanel",
	Size                   = UDim2.new(0, 220, 0, 44),
	Position               = UDim2.new(0.5, -110, 1, -54),
	BackgroundColor3       = Color3.fromRGB(10, 10, 20),
	BackgroundTransparency = 0.15,
	BorderSizePixel        = 0,
	Visible                = false,
	ZIndex                 = 12,
}, mainHUD)
make("UICorner", { CornerRadius=UDim.new(0,10) }, miniPanel)
make("UIStroke",  { Color=Color3.fromRGB(255,220,0), Thickness=1.5, Transparency=0.4 }, miniPanel)
local miniLabel = make("TextLabel", {
	Name="MiniLabel", Size=UDim2.new(0.72,0,1,0), Position=UDim2.new(0,8,0,0),
	BackgroundTransparency=1, TextColor3=Color3.new(1,1,1),
	TextScaled=true, Font=Enum.Font.GothamBold, Text="⏳ Не выбрано",
	TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
}, miniPanel)
local miniTimer = make("TextLabel", {
	Name="MiniTimer", Size=UDim2.new(0.26,0,1,0), Position=UDim2.new(0.74,0,0,0),
	BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,100),
	TextScaled=true, Font=Enum.Font.GothamBold, Text="", ZIndex=13,
}, miniPanel)

-- Fade Frame (заглушка, затемнение убрано)
make("Frame", {
	Name="FadeFrame", Size=UDim2.new(1,0,1,0),
	BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=1,
	Visible=false, ZIndex=20, BorderSizePixel=0,
}, mainHUD)

print("[ClientBootstrap] MainHUD создан.")

-- ══════════════════════════════════════════════════════════════
--  REMOTES
-- ══════════════════════════════════════════════════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
if not Remotes then warn("[ClientBootstrap] Remotes не найдены.") return end

local RoundState      = Remotes:WaitForChild("RoundState")
local HUDMessage      = Remotes:WaitForChild("HUDMessage")
local RoundResult     = Remotes:WaitForChild("RoundResult")
local PlayCelebration = Remotes:WaitForChild("PlayCelebration")
local SubmitChoice    = Remotes:WaitForChild("SubmitChoice")

-- ══════════════════════════════════════════════════════════════
--  SHARED
-- ══════════════════════════════════════════════════════════════
local Enums      = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local UIConfig   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("UIConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

-- ══════════════════════════════════════════════════════════════
--  INLINE CHOICE CONTROLLER
--  (не зависит от внешнего модуля — всё в одном месте)
-- ══════════════════════════════════════════════════════════════
local POS_HIDDEN  = UDim2.new(0, 0, 1,    0)
local POS_VISIBLE = UDim2.new(0, 0, 0.58, 0)

local TWEEN_IN  = TweenInfo.new(0.55, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
local TWEEN_SEL = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

local COLOR_SELECTED   = Color3.fromRGB(255, 220, 0)
local COLOR_UNSELECTED = Color3.fromRGB(80,  80,  80)
local COLOR_DIM        = Color3.fromRGB(40,  40,  40)

local leftBorder  = leftCard:FindFirstChildOfClass("UIStroke")
local rightBorder = rightCard:FindFirstChildOfClass("UIStroke")

local currentSide   = nil
local choiceEnabled = false
local isCollapsed   = false
local timerThread   = nil

local function splitEmoji(text)
	local emoji, name = text:match("^(%S+)%s+(.+)$")
	if emoji and name then return emoji, name end
	return "", text
end

local function setLeftText(text)
	local e, n = splitEmoji(text)
	leftCard:FindFirstChild("Emoji").Text = e
	leftCard:FindFirstChild("Label").Text = n
end

local function setRightText(text)
	local e, n = splitEmoji(text)
	rightCard:FindFirstChild("Emoji").Text = e
	rightCard:FindFirstChild("Label").Text = n
end

local function highlightSide(side)
	if side == Enums.Team.Left then
		TweenService:Create(leftBorder,  TWEEN_SEL, { Color=COLOR_SELECTED,   Thickness=5 }):Play()
		TweenService:Create(rightBorder, TWEEN_SEL, { Color=COLOR_DIM,        Thickness=2 }):Play()
		TweenService:Create(leftCard,    TWEEN_SEL, { BackgroundTransparency=0.0  }):Play()
		TweenService:Create(rightCard,   TWEEN_SEL, { BackgroundTransparency=0.55 }):Play()
	elseif side == Enums.Team.Right then
		TweenService:Create(rightBorder, TWEEN_SEL, { Color=COLOR_SELECTED,   Thickness=5 }):Play()
		TweenService:Create(leftBorder,  TWEEN_SEL, { Color=COLOR_DIM,        Thickness=2 }):Play()
		TweenService:Create(rightCard,   TWEEN_SEL, { BackgroundTransparency=0.0  }):Play()
		TweenService:Create(leftCard,    TWEEN_SEL, { BackgroundTransparency=0.55 }):Play()
	else
		TweenService:Create(leftBorder,  TWEEN_SEL, { Color=COLOR_UNSELECTED, Thickness=3 }):Play()
		TweenService:Create(rightBorder, TWEEN_SEL, { Color=COLOR_UNSELECTED, Thickness=3 }):Play()
		TweenService:Create(leftCard,    TWEEN_SEL, { BackgroundTransparency=0.05 }):Play()
		TweenService:Create(rightCard,   TWEEN_SEL, { BackgroundTransparency=0.05 }):Play()
	end
end

local function updateMiniLabel(side)
	if side == Enums.Team.Left then
		miniLabel.Text       = "✅ " .. leftCard:FindFirstChild("Label").Text
		miniLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	elseif side == Enums.Team.Right then
		miniLabel.Text       = "✅ " .. rightCard:FindFirstChild("Label").Text
		miniLabel.TextColor3 = Color3.fromRGB(255, 140, 80)
	else
		miniLabel.Text       = "⏳ Не выбрано"
		miniLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end

local function stopTimer()
	if timerThread then task.cancel(timerThread) timerThread = nil end
	voteTimerFrame.Visible = false
end

local function startTimer(seconds)
	stopTimer()
	voteTimerFrame.Visible = true
	voteTimerLabel.Text    = tostring(seconds)
	miniTimer.Text         = tostring(seconds)
	timerThread = task.spawn(function()
		for i = seconds, 0, -1 do
			voteTimerLabel.Text = tostring(i)
			miniTimer.Text      = tostring(i)
			if i <= 5 then
				voteTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				miniTimer.TextColor3      = Color3.fromRGB(255, 80, 80)
				-- пульс
				voteTimerLabel.TextSize = 28
				TweenService:Create(voteTimerLabel,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextSize = 18 }):Play()
			else
				voteTimerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
				miniTimer.TextColor3      = Color3.fromRGB(255, 255, 100)
			end
			if i > 0 then task.wait(1) end
		end
		voteTimerFrame.Visible = false
	end)
end

local function slideIn()
	isCollapsed = false
	collapseBtn.Text    = "▼"
	choicePanel.Visible = true
	miniPanel.Visible   = false
	choicePanel.Position = POS_HIDDEN
	TweenService:Create(choicePanel, TWEEN_IN, { Position = POS_VISIBLE }):Play()
end

local function slideOut()
	TweenService:Create(choicePanel, TWEEN_OUT, { Position = POS_HIDDEN }):Play()
	task.delay(0.36, function() choicePanel.Visible = false end)
	miniPanel.Visible = false
end

local function collapse()
	if isCollapsed then return end
	isCollapsed = true
	collapseBtn.Text = "▲"
	updateMiniLabel(currentSide)
	TweenService:Create(choicePanel, TWEEN_OUT, { Position = POS_HIDDEN }):Play()
	task.delay(0.2, function()
		choicePanel.Visible = false
		miniPanel.Visible   = true
	end)
end

local function expand()
	if not isCollapsed then return end
	isCollapsed = false
	collapseBtn.Text    = "▼"
	miniPanel.Visible   = false
	choicePanel.Visible = true
	choicePanel.Position = POS_HIDDEN
	TweenService:Create(choicePanel, TWEEN_IN, { Position = POS_VISIBLE }):Play()
end

local function selectSide(side)
	if not choiceEnabled then return end
	currentSide = side
	SubmitChoice:FireServer({ Side = side })
	highlightSide(side)
	updateMiniLabel(side)
	-- кнопочный bounce
	local btn = (side == Enums.Team.Left) and leftBtn or rightBtn
	local orig = btn.Size
	TweenService:Create(btn, TweenInfo.new(0.07), { Size = orig - UDim2.new(0.04,0,0.06,0) }):Play()
	task.delay(0.07, function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = orig }):Play()
	end)
end

-- Кнопки
leftBtn.MouseButton1Click:Connect(function()  selectSide(Enums.Team.Left)  end)
rightBtn.MouseButton1Click:Connect(function() selectSide(Enums.Team.Right) end)
collapseBtn.MouseButton1Click:Connect(function()
	if isCollapsed then expand() else collapse() end
end)
miniPanel.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
		expand()
	end
end)

-- ══════════════════════════════════════════════════════════════
--  HUD HELPERS
-- ══════════════════════════════════════════════════════════════
local topStatus  = topBar:WaitForChild("TopStatus")
local timerLabel = mainHUD:WaitForChild("TimerLabel")
local roundBanner = mainHUD:WaitForChild("RoundBanner")
local resultLabel = resultPanel:WaitForChild("ResultLabel")

local function setStatus(text, color)
	topStatus.Text       = (GameConfig.TEST_MODE and "[TEST] " or "") .. (text or "")
	topStatus.TextColor3 = color or Color3.new(1,1,1)
end

local function setTimer(seconds)
	if seconds == nil then
		timerLabel.Text    = ""
		timerLabel.Visible = false
		return
	end
	timerLabel.Visible    = true
	timerLabel.Text       = string.format("%d:%02d", math.floor(seconds/60), seconds%60)
	timerLabel.TextColor3 = seconds <= 5
		and Color3.fromRGB(255, 80, 80)
		or  Color3.fromRGB(255, 255, 255)
end

local function showBanner(text, color)
	roundBanner.Text        = text
	roundBanner.TextColor3  = color or Color3.new(1,1,1)
	roundBanner.TextTransparency = 0
	roundBanner.Visible = true
	task.delay(2.5, function()
		TweenService:Create(roundBanner,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextTransparency = 1 }):Play()
		task.delay(0.4, function() roundBanner.Visible = false end)
	end)
end

local function showResult(isWinner, isDraw)
	resultPanel.Visible = true
	resultPanel.BackgroundTransparency = 1
	if isDraw then
		resultLabel.Text       = "🤝 Ничья"
		resultLabel.TextColor3 = Color3.fromRGB(200,200,200)
	elseif isWinner then
		resultLabel.Text       = "🏆 ПОБЕДА!"
		resultLabel.TextColor3 = Color3.fromRGB(255,220,0)
	else
		resultLabel.Text       = "💀 Поражение"
		resultLabel.TextColor3 = Color3.fromRGB(200,60,60)
	end
	TweenService:Create(resultPanel,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.25 }):Play()
end

local function hideResult()
	TweenService:Create(resultPanel,
		TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	task.delay(0.3, function() resultPanel.Visible = false end)
end

local function choiceRevealA(text, color)
	setLeftText(text)
	leftCard.BackgroundColor3       = color or Color3.fromRGB(20,80,200)
	leftCard.BackgroundTransparency = 0.05
	rightCard:FindFirstChild("Emoji").Text = "?"
	rightCard:FindFirstChild("Label").Text = "???"
	rightCard.BackgroundTransparency = 0.75
	rightBtn.BackgroundTransparency  = 0.85
	highlightSide(nil)
	choiceEnabled = false
	slideIn()
end

local function choiceRevealB(text, color)
	setRightText(text)
	rightCard.BackgroundColor3       = color or Color3.fromRGB(180,50,10)
	rightCard.BackgroundTransparency = 0.75
	rightBtn.BackgroundTransparency  = 0.85
	-- анимация появления правой карты
	rightCard.Size = UDim2.new(0.36, 0, 0.88, 0)
	TweenService:Create(rightCard,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0.46,0,0.88,0), BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(rightBtn,
		TweenInfo.new(0.4),
		{ BackgroundTransparency = 0.1 }):Play()
end

local function choiceShowFull(data)
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
	if not choicePanel.Visible or choicePanel.Position == POS_HIDDEN then
		slideIn()
	end
	if data.Duration then startTimer(data.Duration) end
end

local function choiceHide()
	choiceEnabled = false
	currentSide   = nil
	stopTimer()
	if choicePanel.Visible then slideOut() end
	miniPanel.Visible = false
end

-- ══════════════════════════════════════════════════════════════
--  CONTROLLERS (только те что нужны)
-- ══════════════════════════════════════════════════════════════
local Controllers = script.Parent:WaitForChild("Controllers")
local CombatController      = require(Controllers:WaitForChild("CombatController"))
local CelebrationController = require(Controllers:WaitForChild("CelebrationController"))

CombatController.Init()
CelebrationController.Init()

-- ══════════════════════════════════════════════════════════════
--  ROUND STATE LISTENER
-- ══════════════════════════════════════════════════════════════
RoundState.OnClientEvent:Connect(function(data)
	local phase = data.Phase

	-- Только таймер боя
	if data.Timer ~= nil and phase == nil then
		setTimer(data.Timer)
		return
	end
	-- Таймер голосования
	if data.Timer ~= nil and phase == Enums.Phase.DarkChoice then
		setTimer(data.Timer)
		voteTimerLabel.Text = tostring(math.max(0, data.Timer))
		miniTimer.Text      = tostring(math.max(0, data.Timer))
		return
	end

	if phase == Enums.Phase.Intermission then
		setStatus("⏳ Ожидание игроков...", Color3.fromRGB(180,180,180))
		setTimer(nil)
		hideResult()
		choiceHide()
		CombatController.SetActive(false)

	elseif phase == Enums.Phase.TeleportToPreArena then
		setStatus("🚀 Телепортация на арену...", Color3.fromRGB(100,200,255))
		choiceHide()

	elseif phase == Enums.Phase.RevealChoiceA then
		setStatus("👁 Выбор А...", Color3.fromRGB(180,180,255))
		if data.Data then choiceRevealA(data.Data.Text, data.Data.Color) end

	elseif phase == Enums.Phase.RevealChoiceB then
		setStatus("👁 Выбор Б...", Color3.fromRGB(180,255,180))
		if data.Data then choiceRevealB(data.Data.Text, data.Data.Color) end

	elseif phase == Enums.Phase.DarkChoice then
		setStatus("🗳 Выбери сторону!", Color3.fromRGB(255,255,100))
		if data.Data then
			choiceShowFull(data.Data)
			setTimer(data.Data.Duration)
		end

	elseif phase == Enums.Phase.LockChoice then
		setStatus("🔒 Выборы зафиксированы!", Color3.fromRGB(200,200,200))
		setTimer(nil)
		stopTimer()

	elseif phase == Enums.Phase.AssignTeams then
		setStatus("⚔ Формируем команды...", Color3.fromRGB(100,255,100))
		choiceHide()

	elseif phase == Enums.Phase.TeleportToBattle then
		setStatus("🏟 На арену!", Color3.fromRGB(255,150,0))

	elseif phase == Enums.Phase.Battle then
		CombatController.SetActive(true)
		setStatus("⚔ БОЙ!", Color3.fromRGB(255,50,50))
		if data.Data and data.Data.Duration then setTimer(data.Data.Duration) end

	elseif phase == Enums.Phase.Victory then
		CombatController.SetActive(false)
		setTimer(nil)
		if data.Data then
			local w = data.Data.Winner
			showBanner(
				w == "Draw" and "🤝 Ничья!" or ("🏆 Победила команда " .. w .. "!"),
				w == "Draw" and Color3.fromRGB(200,200,200) or Color3.fromRGB(255,220,0)
			)
		end

	elseif phase == Enums.Phase.Celebration then
		setStatus("🎉 Празднование!", Color3.fromRGB(255,220,0))

	elseif phase == Enums.Phase.ReturnToLobby then
		setStatus("🏠 Возвращение в лобби...", Color3.fromRGB(150,150,255))
		setTimer(nil)

	elseif phase == Enums.Phase.Cleanup then
		setStatus("Раунд завершён.", Color3.fromRGB(160,160,160))
		choiceHide()
		CombatController.SetActive(false)
	end
end)

HUDMessage.OnClientEvent:Connect(function(data)
	if data and data.Message then
		setStatus(data.Message, data.Color)
	end
end)

RoundResult.OnClientEvent:Connect(function(data)
	showResult(data.IsWinner, data.IsDraw)
end)

PlayCelebration.OnClientEvent:Connect(function(data)
	CelebrationController.PlayCelebration(data.AnimId)
	CelebrationController.PlaySound(data.SfxId)
end)

print("[ClientBootstrap] Готов,", localPlayer.Name)