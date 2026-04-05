-- LocalScript: StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua

local playMusic
local stopMusic

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local SoundService      = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════
-- РЕМОУТЫ
-- ══════════════════════════════════════════════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
assert(Remotes, "[ClientBootstrap] Remotes не найдены!")

local RoundStateRemote   = Remotes:WaitForChild("RoundState")
local HUDMessageRemote   = Remotes:WaitForChild("HUDMessage")
local RoundResultRemote  = Remotes:WaitForChild("RoundResult")
local PlayCelebRemote    = Remotes:WaitForChild("PlayCelebration")
local SyncDarkRemote     = Remotes:WaitForChild("SyncDarkness")
local SubmitChoiceRemote = Remotes:WaitForChild("SubmitChoice")
local CombatInputRemote  = Remotes:WaitForChild("CombatInput")

-- ══════════════════════════════════════════════════════════
-- КОНФИГИ
-- ══════════════════════════════════════════════════════════
local Enums         = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local GameConfig    = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local CombatConfig  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CombatConfig"))
local ContentConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ContentConfig"))

local PLACEHOLDER = "rbxassetid://112107392394775"

-- ══════════════════════════════════════════════════════════
-- МУЗЫКАЛЬНЫЙ МЕНЕДЖЕР
-- ══════════════════════════════════════════════════════════
local phaseMusic              = Instance.new("Sound")
phaseMusic.Name               = "PhaseMusic"
phaseMusic.Volume             = 0.6
phaseMusic.Looped             = true
phaseMusic.RollOffMaxDistance = 0
phaseMusic.Parent             = SoundService

local currentMusicId  = 0
local musicStopThread = nil

local function cancelStopThread()
	if musicStopThread then
		local t = musicStopThread
		musicStopThread = nil
		pcall(task.cancel, t)  -- pcall: если поток уже мёртв — просто игнорируем
	end
end

playMusic = function(soundId, maxDuration)
	cancelStopThread()

	if not soundId or soundId == 0 then
		phaseMusic:Stop()
		currentMusicId = 0
		return
	end

	local fullId = "rbxassetid://" .. tostring(soundId)
	if phaseMusic.SoundId == fullId and phaseMusic.IsPlaying then
		-- Тот же трек уже играет — просто перезапускаем авто-стоп
		if maxDuration then
			musicStopThread = task.delay(maxDuration, function()
				musicStopThread = nil
				stopMusic(1.5)
			end)
		end
		return
	end

	phaseMusic:Stop()
	phaseMusic.SoundId      = fullId
	phaseMusic.TimePosition = 0
	phaseMusic:Play()
	currentMusicId = soundId
	print(string.format("[ClientBootstrap] Music -> rbxassetid://%d (max %ds)",
		soundId, maxDuration or 0))

	if maxDuration and maxDuration > 0 then
		musicStopThread = task.delay(maxDuration, function()
			musicStopThread = nil  -- обнуляем ДО stopMusic чтобы cancelStopThread внутри не трогал мёртвый поток
			stopMusic(1.5)
		end)
	end
end

stopMusic = function(fadeDuration)
	cancelStopThread()

	fadeDuration = fadeDuration or 0
	if fadeDuration > 0 then
		TweenService:Create(phaseMusic,
			TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear),
			{ Volume = 0 }
		):Play()
		task.delay(fadeDuration, function()
			phaseMusic:Stop()
			phaseMusic.Volume = 0.6
		end)
	else
		phaseMusic:Stop()
	end
	currentMusicId = 0
end

-- ══════════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════════
local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do pcall(function() inst[k] = v end) end
	if parent then inst.Parent = parent end
	return inst
end

local function tw(inst, props, t, style, dir)
	if not inst or not inst.Parent then return end
	TweenService:Create(inst,
		TweenInfo.new(t or 0.25,
			style or Enum.EasingStyle.Quart,
			dir   or Enum.EasingDirection.Out),
		props):Play()
end

local function resolveImage(id)
	if id and id ~= 0 then
		return "rbxassetid://" .. tostring(id)
	end
	return PLACEHOLDER
end

-- ══════════════════════════════════════════════════════════
-- СТРОИМ MainHUD
-- ══════════════════════════════════════════════════════════
local old = playerGui:FindFirstChild("MainHUD")
if old then old:Destroy() end

local mainHUD = make("ScreenGui", {
	Name = "MainHUD", ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true, DisplayOrder = 10,
}, playerGui)

-- ── TOP BAR ──────────────────────────────────────────────
local topBar = make("Frame", {
	Size = UDim2.new(1,0,0,56), Position = UDim2.new(0,0,0,0),
	BackgroundColor3 = Color3.fromRGB(8,8,18), BorderSizePixel = 0, ZIndex = 5,
}, mainHUD)
make("UIGradient", {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18,14,40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,18)),
	}, Rotation = 90,
}, topBar)
make("Frame", {
	Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2),
	BackgroundColor3 = Color3.fromRGB(255,200,50),
	BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 6,
}, topBar)

local topStatus = make("TextLabel", {
	Name = "TopStatus",
	Size = UDim2.new(1,-24,1,0), Position = UDim2.new(0,12,0,0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(240,235,255),
	TextScaled = true, Font = Enum.Font.GothamBold,
	Text = GameConfig.TEST_MODE and "[TEST] Ожидание..." or "Ожидание...",
	TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6,
}, topBar)

if GameConfig.TEST_MODE then
	local badge = make("Frame", {
		Size = UDim2.new(0,90,0,22), Position = UDim2.new(1,-96,0.5,-11),
		BackgroundColor3 = Color3.fromRGB(255,160,0), BorderSizePixel = 0, ZIndex = 7,
	}, topBar)
	make("UICorner", { CornerRadius = UDim.new(0,6) }, badge)
	make("TextLabel", {
		Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(255,255,255),
		Font = Enum.Font.GothamBold, Text = "TEST MODE", TextScaled = true, ZIndex = 8,
	}, badge)
end

-- ── TIMER ─────────────────────────────────────────────────
local timerContainer = make("Frame", {
	Name = "TimerContainer",
	Size = UDim2.new(0,110,0,50), Position = UDim2.new(0.5,-55,0,62),
	BackgroundColor3 = Color3.fromRGB(0,0,0),
	BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5, Visible = false,
}, mainHUD)
make("UICorner", { CornerRadius = UDim.new(0,10) }, timerContainer)
make("UIStroke", { Color = Color3.fromRGB(255,200,50), Thickness = 1.5, Transparency = 0.5 }, timerContainer)
local timerLabel = make("TextLabel", {
	Name = "TimerLabel",
	Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255,255,255),
	TextScaled = true, Font = Enum.Font.GothamBold, Text = "", ZIndex = 6,
}, timerContainer)

-- ── ROUND BANNER ──────────────────────────────────────────
local roundBanner = make("TextLabel", {
	Name = "RoundBanner",
	Size = UDim2.new(0.8,0,0,70), Position = UDim2.new(0.1,0,0.3,0),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255,220,50), TextScaled = true,
	Font = Enum.Font.GothamBold, Text = "", Visible = false, ZIndex = 8,
	TextStrokeTransparency = 0.4, TextStrokeColor3 = Color3.fromRGB(0,0,0),
}, mainHUD)

-- ── CHOICE PANEL ──────────────────────────────────────────
local choicePanel = make("Frame", {
	Name = "ChoicePanel",
	Size = UDim2.new(0.92,0,0,180), Position = UDim2.new(0.04,0,1,-196),
	BackgroundTransparency = 1, Visible = false, ZIndex = 6,
}, mainHUD)

-- LEFT CARD
local leftCard = make("Frame", {
	Name = "LeftCard",
	Size = UDim2.new(0.47,0,1,0), Position = UDim2.new(0,0,0,0),
	BackgroundColor3 = Color3.fromRGB(20,80,210), BorderSizePixel = 0, ZIndex = 6,
}, choicePanel)
make("UICorner", { CornerRadius = UDim.new(0,14) }, leftCard)
make("UIStroke", { Color = Color3.fromRGB(80,80,80), Thickness = 2.5 }, leftCard)
make("UIGradient", {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40,110,255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10,50,160)),
	}, Rotation = 120,
}, leftCard)
local leftIcon = make("ImageLabel", {
	Name = "Icon", Size = UDim2.new(0.55,0,0.42,0), Position = UDim2.new(0.225,0,0.04,0),
	BackgroundTransparency = 1, Image = PLACEHOLDER, ZIndex = 7,
}, leftCard)
make("UICorner", { CornerRadius = UDim.new(0,8) }, leftIcon)
local leftLabel = make("TextLabel", {
	Name = "Label",
	Size = UDim2.new(1,-8,0.24,0), Position = UDim2.new(0,4,0.48,0),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255),
	TextScaled = true, Font = Enum.Font.GothamBold, Text = "Left", ZIndex = 7,
	TextStrokeTransparency = 0.5, TextStrokeColor3 = Color3.fromRGB(0,0,0),
}, leftCard)
local leftBtn = make("TextButton", {
	Name = "Button",
	Size = UDim2.new(0.72,0,0.22,0), Position = UDim2.new(0.14,0,0.74,0),
	BackgroundColor3 = Color3.fromRGB(255,255,255),
	TextColor3 = Color3.fromRGB(20,50,160), Font = Enum.Font.GothamBold,
	Text = "Выбрать!", TextScaled = true, ZIndex = 7, BorderSizePixel = 0,
}, leftCard)
make("UICorner", { CornerRadius = UDim.new(0,8) }, leftBtn)

-- RIGHT CARD
local rightCard = make("Frame", {
	Name = "RightCard",
	Size = UDim2.new(0.47,0,1,0), Position = UDim2.new(0.53,0,0,0),
	BackgroundColor3 = Color3.fromRGB(190,55,10), BorderSizePixel = 0, ZIndex = 6,
}, choicePanel)
make("UICorner", { CornerRadius = UDim.new(0,14) }, rightCard)
make("UIStroke", { Color = Color3.fromRGB(80,80,80), Thickness = 2.5 }, rightCard)
make("UIGradient", {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255,90,20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(140,30,0)),
	}, Rotation = 120,
}, rightCard)
local rightIcon = make("ImageLabel", {
	Name = "Icon", Size = UDim2.new(0.55,0,0.42,0), Position = UDim2.new(0.225,0,0.04,0),
	BackgroundTransparency = 1, Image = PLACEHOLDER, ZIndex = 7,
}, rightCard)
make("UICorner", { CornerRadius = UDim.new(0,8) }, rightIcon)
local rightLabel = make("TextLabel", {
	Name = "Label",
	Size = UDim2.new(1,-8,0.24,0), Position = UDim2.new(0,4,0.48,0),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255),
	TextScaled = true, Font = Enum.Font.GothamBold, Text = "Right", ZIndex = 7,
	TextStrokeTransparency = 0.5, TextStrokeColor3 = Color3.fromRGB(0,0,0),
}, rightCard)
local rightBtn = make("TextButton", {
	Name = "Button",
	Size = UDim2.new(0.72,0,0.22,0), Position = UDim2.new(0.14,0,0.74,0),
	BackgroundColor3 = Color3.fromRGB(255,255,255),
	TextColor3 = Color3.fromRGB(160,30,0), Font = Enum.Font.GothamBold,
	Text = "Выбрать!", TextScaled = true, ZIndex = 7, BorderSizePixel = 0,
}, rightCard)
make("UICorner", { CornerRadius = UDim.new(0,8) }, rightBtn)

-- ── TOGGLE BTN ────────────────────────────────────────────
local toggleBtn = make("TextButton", {
	Name = "ToggleChoiceBtn",
	Size = UDim2.new(0,120,0,30),
	Position = UDim2.new(1,-128,1,-236),
	BackgroundColor3 = Color3.fromRGB(20,20,35),
	BackgroundTransparency = 0.25,
	TextColor3 = Color3.fromRGB(200,200,255),
	Font = Enum.Font.GothamSemibold,
	Text = "👁 Скрыть",
	TextScaled = true,
	Visible = false, ZIndex = 12, BorderSizePixel = 0,
}, mainHUD)
make("UICorner", { CornerRadius = UDim.new(0,8) }, toggleBtn)
make("UIStroke", {
	Color = Color3.fromRGB(120,100,255), Thickness = 1.5, Transparency = 0.4,
}, toggleBtn)

-- ── RESULT PANEL ──────────────────────────────────────────
local resultPanel = make("Frame", {
	Name = "ResultPanel",
	Size = UDim2.new(0,340,0,130), Position = UDim2.new(0.5,-170,0.5,-65),
	BackgroundColor3 = Color3.fromRGB(10,8,24),
	BackgroundTransparency = 0.12, BorderSizePixel = 0, Visible = false, ZIndex = 9,
}, mainHUD)
make("UICorner", { CornerRadius = UDim.new(0,18) }, resultPanel)
make("UIStroke", { Color = Color3.fromRGB(255,200,50), Thickness = 2, Transparency = 0.3 }, resultPanel)
local resultLabel = make("TextLabel", {
	Name = "ResultLabel",
	Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255,220,50), TextScaled = true,
	Font = Enum.Font.GothamBold, Text = "", ZIndex = 10,
	TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.fromRGB(0,0,0),
}, resultPanel)

-- ── FADE FRAME ────────────────────────────────────────────
local fadeFrame = make("Frame", {
	Name = "FadeFrame",
	Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(0,0,0),
	BackgroundTransparency = 1, Visible = false, ZIndex = 20, BorderSizePixel = 0,
}, mainHUD)

print("[ClientBootstrap] MainHUD создан.")

-- ══════════════════════════════════════════════════════════
-- СОСТОЯНИЕ КЛИЕНТА
-- ══════════════════════════════════════════════════════════
local currentPhase  = nil
local choiceEnabled = false
local currentSide   = nil
local panelVisible  = true
local battleActive  = false

-- ══════════════════════════════════════════════════════════
-- HUD HELPERS
-- ══════════════════════════════════════════════════════════
local function setStatus(text, color)
	topStatus.Text       = (GameConfig.TEST_MODE and "[TEST] " or "") .. (text or "")
	topStatus.TextColor3 = color or Color3.fromRGB(240,235,255)
end

local function setTimer(seconds)
	if not seconds or seconds < 0 then
		timerContainer.Visible = false
		return
	end
	timerContainer.Visible = true
	local s = math.max(0, math.floor(seconds))
	timerLabel.Text        = string.format("%d:%02d", math.floor(s/60), s%60)
	timerLabel.TextColor3  = s <= 5
		and Color3.fromRGB(255,80,50)
		or  Color3.fromRGB(255,255,255)
end

local function showBanner(text, color, duration)
	roundBanner.Text             = text
	roundBanner.TextColor3       = color or Color3.fromRGB(255,220,50)
	roundBanner.TextTransparency = 0
	roundBanner.Visible          = true
	tw(roundBanner, { TextTransparency = 1 }, duration or 2.5, Enum.EasingStyle.Linear)
	task.delay(duration or 2.5, function()
		roundBanner.Visible = false
	end)
end

local function showResult(isWinner, isDraw)
	resultPanel.Visible               = true
	resultPanel.BackgroundTransparency = 1
	resultLabel.Text = isDraw     and "🤝 Ничья!"
		or isWinner  and "🏆 ПОБЕДА!"
		or               "💀 Поражение"
	resultLabel.TextColor3 = isDraw    and Color3.fromRGB(200,200,200)
		or isWinner         and Color3.fromRGB(255,220,50)
		or                      Color3.fromRGB(220,80,60)
	tw(resultPanel, { BackgroundTransparency = 0.12 }, 0.4)
end

local function hideResult()
	tw(resultPanel, { BackgroundTransparency = 1 }, 0.3)
	task.delay(0.35, function() resultPanel.Visible = false end)
end

local function fadeTransition(toAlpha, duration)
	fadeFrame.Visible = true
	tw(fadeFrame, { BackgroundTransparency = 1 - toAlpha }, duration or 0.35)
	if toAlpha <= 0 then
		task.delay((duration or 0.35) + 0.05, function()
			fadeFrame.Visible = false
		end)
	end
end

-- ══════════════════════════════════════════════════════════
-- CHOICE PANEL HELPERS
-- ══════════════════════════════════════════════════════════
local function setCardImage(icon, imageId)
	icon.Image = resolveImage(imageId)
end

local function refreshBorders()
	local ls = leftCard:FindFirstChildOfClass("UIStroke")
	local rs = rightCard:FindFirstChildOfClass("UIStroke")
	if not ls or not rs then return end
	if currentSide == Enums.Team.Left then
		tw(ls, { Color = Color3.fromRGB(255,215,0), Thickness = 3.5 }, 0.15)
		tw(rs, { Color = Color3.fromRGB(80,80,80),  Thickness = 2.5 }, 0.15)
	elseif currentSide == Enums.Team.Right then
		tw(ls, { Color = Color3.fromRGB(80,80,80),  Thickness = 2.5 }, 0.15)
		tw(rs, { Color = Color3.fromRGB(255,215,0), Thickness = 3.5 }, 0.15)
	else
		tw(ls, { Color = Color3.fromRGB(80,80,80), Thickness = 2.5 }, 0.15)
		tw(rs, { Color = Color3.fromRGB(80,80,80), Thickness = 2.5 }, 0.15)
	end
end

local function applyCardVisibility(visible, animate)
	panelVisible  = visible
	local targetT = visible and 0 or 1
	local dur     = animate and 0.25 or 0
	for _, card in ipairs({leftCard, rightCard}) do
		if not card then continue end
		if animate then
			tw(card, { BackgroundTransparency = targetT }, dur)
		else
			card.BackgroundTransparency = targetT
		end
		for _, child in ipairs(card:GetDescendants()) do
			if child:IsA("TextLabel") then
				if animate then tw(child, { TextTransparency = targetT }, dur)
				else child.TextTransparency = targetT end
			elseif child:IsA("TextButton") then
				if animate then
					tw(child, { TextTransparency = targetT, BackgroundTransparency = targetT }, dur)
				else
					child.TextTransparency       = targetT
					child.BackgroundTransparency = targetT
				end
			elseif child:IsA("ImageLabel") then
				if animate then tw(child, { ImageTransparency = targetT }, dur)
				else child.ImageTransparency = targetT end
			elseif child:IsA("UIStroke") then
				if animate then tw(child, { Transparency = targetT }, dur)
				else child.Transparency = targetT end
			end
		end
	end
	toggleBtn.Text = visible and "👁 Скрыть" or "👁 Показать"
end

local function showChoicePanel(data)
	leftCard.Position  = UDim2.new(0,0,0,0)
	rightCard.Position = UDim2.new(0.53,0,0,0)
	applyCardVisibility(true, false)
	if data then
		leftLabel.Text  = data.LeftText  or "Лево"
		rightLabel.Text = data.RightText or "Право"
		setCardImage(leftIcon,  data.LeftImage)
		setCardImage(rightIcon, data.RightImage)
	end
	leftCard.Visible    = true
	rightCard.Visible   = true
	choicePanel.Visible = true
	currentSide  = nil
	panelVisible = true
	refreshBorders()
end

local function hideChoicePanel(animate)
	choiceEnabled = false
	if animate then
		tw(leftCard,  { Position = UDim2.new(-0.55,0,0,0), BackgroundTransparency = 1 }, 0.3)
		tw(rightCard, { Position = UDim2.new( 1.08,0,0,0), BackgroundTransparency = 1 }, 0.3)
		task.delay(0.35, function()
			choicePanel.Visible = false
			leftCard.Position   = UDim2.new(0,0,0,0)
			rightCard.Position  = UDim2.new(0.53,0,0,0)
			applyCardVisibility(true, false)
		end)
	else
		choicePanel.Visible = false
	end
	tw(toggleBtn, { BackgroundTransparency = 1 }, 0.2)
	task.delay(0.25, function() toggleBtn.Visible = false end)
end

-- ── Кнопка скрыть ─────────────────────────────────────────
toggleBtn.MouseButton1Click:Connect(function()
	applyCardVisibility(not panelVisible, true)
end)
toggleBtn.MouseEnter:Connect(function()
	tw(toggleBtn, { BackgroundTransparency = 0.05 }, 0.12)
end)
toggleBtn.MouseLeave:Connect(function()
	tw(toggleBtn, { BackgroundTransparency = 0.25 }, 0.12)
end)

-- ── Кнопки выбора ─────────────────────────────────────────
leftBtn.MouseButton1Click:Connect(function()
	if not choiceEnabled then return end
	currentSide = Enums.Team.Left
	SubmitChoiceRemote:FireServer({ Side = Enums.Team.Left })
	refreshBorders()
end)
leftBtn.MouseEnter:Connect(function()
	if not choiceEnabled then return end
	tw(leftBtn, { BackgroundColor3 = Color3.fromRGB(220,225,255) }, 0.12)
end)
leftBtn.MouseLeave:Connect(function()
	tw(leftBtn, { BackgroundColor3 = Color3.fromRGB(255,255,255) }, 0.12)
end)

rightBtn.MouseButton1Click:Connect(function()
	if not choiceEnabled then return end
	currentSide = Enums.Team.Right
	SubmitChoiceRemote:FireServer({ Side = Enums.Team.Right })
	refreshBorders()
end)
rightBtn.MouseEnter:Connect(function()
	if not choiceEnabled then return end
	tw(rightBtn, { BackgroundColor3 = Color3.fromRGB(255,220,210) }, 0.12)
end)
rightBtn.MouseLeave:Connect(function()
	tw(rightBtn, { BackgroundColor3 = Color3.fromRGB(255,255,255) }, 0.12)
end)

-- ══════════════════════════════════════════════════════════
-- COMBAT
-- ══════════════════════════════════════════════════════════
local lastAttack = 0

local function findClosestEnemy()
	local char = localPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local best, bestDist = nil, CombatConfig.ATTACK_RANGE
	for _, p in ipairs(Players:GetPlayers()) do
		if p == localPlayer then continue end
		local c = p.Character
		if not c then continue end
		local h = c:FindFirstChild("HumanoidRootPart")
		if not h then continue end
		local d = (hrp.Position - h.Position).Magnitude
		if d < bestDist then bestDist = d; best = p end
	end
	return best
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not battleActive then return end
	local now = tick()
	if input.KeyCode == Enum.KeyCode.F
	or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if now - lastAttack < CombatConfig.ATTACK_COOLDOWN then return end
		lastAttack = now
		local t = findClosestEnemy()
		if t then
			CombatInputRemote:FireServer({
				Action   = Enums.CombatAction.Melee,
				TargetId = t.UserId,
			})
		end
	end
end)

print("[ClientBootstrap] Combat input ready. Keys: F / Click = Attack")

-- ══════════════════════════════════════════════════════════
-- CELEBRATION
-- ══════════════════════════════════════════════════════════
local function playCelebration(animId, sfxId)
	local char = localPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and animId and animId ~= 0 then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animId)
		local track = hum:LoadAnimation(anim)
		if track then track:Play() end
	end
	if sfxId and sfxId ~= 0 then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local snd = Instance.new("Sound")
			snd.SoundId = "rbxassetid://" .. tostring(sfxId)
			snd.Volume  = 0.8
			snd.Parent  = hrp
			snd:Play()
			snd.Ended:Connect(function() snd:Destroy() end)
		end
	end
end

-- ══════════════════════════════════════════════════════════
-- REMOTE LISTENERS
-- ══════════════════════════════════════════════════════════
local MUSIC = ContentConfig.PHASE_MUSIC

RoundStateRemote.OnClientEvent:Connect(function(data)
	local phase = data.Phase

	-- Тик таймера без смены фазы
	if data.Timer ~= nil and phase == nil then
		setTimer(data.Timer)
		return
	end
	-- Тик таймера во время DarkChoice
	if data.Timer ~= nil and phase == Enums.Phase.DarkChoice then
		setTimer(data.Timer)
		return
	end

	currentPhase = phase

	if phase == Enums.Phase.Intermission then
		battleActive  = false
		choiceEnabled = false
		hideResult()
		hideChoicePanel(false)
		stopMusic(0.5)
		setStatus("Ожидание...", Color3.fromRGB(180,180,200))
		setTimer(nil)

	elseif phase == Enums.Phase.TeleportToPreArena then
		fadeTransition(0.6, 0.3)
		task.delay(0.4, function() fadeTransition(0, 0.4) end)
		stopMusic(0.3)
		setStatus("Перемещение в арену...", Color3.fromRGB(100,200,255))
		hideChoicePanel(false)

	elseif phase == Enums.Phase.RevealChoiceA then
		choiceEnabled = false
		local d = data.Data or {}
		setCardImage(leftIcon, d.Image)
		if leftLabel and d.Text then leftLabel.Text = d.Text end
		leftCard.Position               = UDim2.new(-0.6,0,0,0)
		leftCard.BackgroundTransparency = 0.8
		leftCard.Visible  = true
		rightCard.Visible = false
		choicePanel.Visible = true
		toggleBtn.Visible   = false
		tw(leftCard, { Position = UDim2.new(0,0,0,0), BackgroundTransparency = 0 }, 0.45, Enum.EasingStyle.Back)
		-- Уникальная музыка варианта A, авто-стоп через REVEAL_A_TIME
		playMusic(d.Music or 0, GameConfig.REVEAL_A_TIME)
		setStatus("Вариант А: " .. (d.Text or "?"), Color3.fromRGB(150,180,255))

	elseif phase == Enums.Phase.RevealChoiceB then
		choiceEnabled = false
		local d = data.Data or {}
		setCardImage(rightIcon, d.Image)
		if rightLabel and d.Text then rightLabel.Text = d.Text end
		rightCard.Position               = UDim2.new(1.1,0,0,0)
		rightCard.BackgroundTransparency = 0.8
		rightCard.Visible = true
		tw(rightCard, { Position = UDim2.new(0.53,0,0,0), BackgroundTransparency = 0 }, 0.45, Enum.EasingStyle.Back)
		-- Уникальная музыка варианта B, авто-стоп через REVEAL_B_TIME
		playMusic(d.Music or 0, GameConfig.REVEAL_B_TIME)
		setStatus("Вариант Б: " .. (d.Text or "?"), Color3.fromRGB(255,160,100))

	elseif phase == Enums.Phase.DarkChoice then
		local d = data.Data or {}
		choiceEnabled = true
		showChoicePanel(d)
		if d.Duration then setTimer(d.Duration) end
		toggleBtn.Visible = true
		toggleBtn.Text    = "👁 Скрыть"
		toggleBtn.BackgroundTransparency = 1
		tw(toggleBtn, { BackgroundTransparency = 0.25 }, 0.3)
		-- Если задана отдельная музыка голосования — переключаем
		-- иначе продолжает играть трек последнего показанного варианта
		if MUSIC.DarkChoice and MUSIC.DarkChoice ~= 0 then
			playMusic(MUSIC.DarkChoice, GameConfig.DARK_CHOICE_TIME)
		end
		setStatus("Выбери сторону!", Color3.fromRGB(255,240,80))

	elseif phase == Enums.Phase.LockChoice then
		choiceEnabled = false
		setTimer(nil)
		stopMusic(0.4)
		setStatus("Выбор зафиксирован!", Color3.fromRGB(180,255,180))
		tw(toggleBtn, { BackgroundTransparency = 1 }, 0.3)
		task.delay(0.35, function() toggleBtn.Visible = false end)

	elseif phase == Enums.Phase.AssignTeams then
		hideChoicePanel(true)
		setStatus("Формируем команды...", Color3.fromRGB(100,255,130))

	elseif phase == Enums.Phase.TeleportToBattle then
		fadeTransition(0.7, 0.3)
		task.delay(0.5, function() fadeTransition(0, 0.4) end)
		setStatus("В бой!", Color3.fromRGB(255,150,0))

	elseif phase == Enums.Phase.Battle then
		battleActive = true
		local d = data.Data or {}
		if d.Duration then setTimer(d.Duration) end
		showBanner("⚔️ БИТВА!", Color3.fromRGB(255,60,60), 2)
		playMusic(MUSIC.Battle, GameConfig.BATTLE_TIME)
		setStatus("⚔️ Сражайся! [F / Click = Атака]", Color3.fromRGB(255,80,80))

	elseif phase == Enums.Phase.Victory then
		battleActive = false
		setTimer(nil)
		stopMusic(0.5)
		local d = data.Data or {}
		local winnerName = d.Winner or "?"
		if winnerName == "Draw" then
			showBanner("🤝 Ничья!", Color3.fromRGB(200,200,200), 3)
		else
			showBanner("🏆 Команда " .. winnerName .. " победила!", Color3.fromRGB(255,220,50), 3)
		end
		setStatus("Раунд завершён", Color3.fromRGB(220,200,100))

	elseif phase == Enums.Phase.Celebration then
		playMusic(MUSIC.Celebration, GameConfig.CELEBRATION_TIME)
		setStatus("🎉 Празднование!", Color3.fromRGB(255,220,50))

	elseif phase == Enums.Phase.ReturnToLobby then
		fadeTransition(0.6, 0.35)
		task.delay(0.5, function() fadeTransition(0, 0.5) end)
		stopMusic(0.6)
		setStatus("Возвращаемся в лобби...", Color3.fromRGB(150,150,255))
		setTimer(nil)

	elseif phase == Enums.Phase.Cleanup then
		battleActive  = false
		choiceEnabled = false
		hideChoicePanel(false)
		stopMusic(0)
		setStatus("Конец раунда.", Color3.fromRGB(150,150,170))
	end
end)

HUDMessageRemote.OnClientEvent:Connect(function(data)
	if data and data.Message then
		setStatus(data.Message, data.Color)
	end
end)

RoundResultRemote.OnClientEvent:Connect(function(data)
	if data then showResult(data.IsWinner, data.IsDraw) end
end)

PlayCelebRemote.OnClientEvent:Connect(function(data)
	if data then playCelebration(data.AnimId, data.SfxId) end
end)

SyncDarkRemote.OnClientEvent:Connect(function(_) end)

print("[ClientBootstrap] Готов,", localPlayer.Name)