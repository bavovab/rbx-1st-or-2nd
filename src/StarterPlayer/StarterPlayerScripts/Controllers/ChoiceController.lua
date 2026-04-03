-- ModuleScript: StarterPlayer/StarterPlayerScripts/Controllers/ChoiceController
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Enums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local SubmitChoice = Remotes:WaitForChild("SubmitChoice")

local ChoiceController = {}

-- ── ссылки на GUI ────────────────────────────────────────
local gui, choicePanel, leftCard, rightCard
local leftLabel, rightLabel, leftBtn, rightBtn, toggleBtn

-- ── состояние ────────────────────────────────────────────
local currentSide   = nil
local choiceEnabled = false
local panelVisible  = true

-- ── tween-хелпер ─────────────────────────────────────────
local function tw(inst, props, t, style, dir)
	if not inst or not inst.Parent then return end
	TweenService:Create(
		inst,
		TweenInfo.new(t or 0.25,
			style or Enum.EasingStyle.Quart,
			dir   or Enum.EasingDirection.Out),
		props
	):Play()
end

-- ── make-хелпер ──────────────────────────────────────────
local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		pcall(function() inst[k] = v end)
	end
	if parent then inst.Parent = parent end
	return inst
end

-- ── создать / найти кнопку скрыть ────────────────────────
local function ensureToggleBtn(mainHUD)
	-- сначала попробуем найти существующую
	local btn = mainHUD:FindFirstChild("ToggleChoiceBtn")
	if btn then return btn end

	-- создаём сами
	btn = make("TextButton", {
		Name             = "ToggleChoiceBtn",
		Size             = UDim2.new(0, 120, 0, 30),
		Position         = UDim2.new(1, -128, 1, -236),
		AnchorPoint      = Vector2.new(0, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 35),
		BackgroundTransparency = 0.25,
		TextColor3       = Color3.fromRGB(200, 200, 255),
		Font             = Enum.Font.GothamSemibold,
		Text             = "👁 Скрыть",
		TextScaled       = true,
		Visible          = false,
		ZIndex           = 12,
		BorderSizePixel  = 0,
	}, mainHUD)
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
	make("UIStroke", {
		Color        = Color3.fromRGB(120, 100, 255),
		Thickness    = 1.5,
		Transparency = 0.4,
	}, btn)
	return btn
end

-- ── обновить рамки по текущему выбору ────────────────────
local function refreshBorders()
	if not leftCard or not rightCard then return end
	local ls = leftCard:FindFirstChildOfClass("UIStroke")
	local rs = rightCard:FindFirstChildOfClass("UIStroke")
	if not ls or not rs then return end

	if currentSide == Enums.Team.Left then
		tw(ls, { Color = Color3.fromRGB(255, 215, 0), Thickness = 3.5 }, 0.15)
		tw(rs, { Color = Color3.fromRGB(80, 80, 80),  Thickness = 2.5 }, 0.15)
	elseif currentSide == Enums.Team.Right then
		tw(ls, { Color = Color3.fromRGB(80, 80, 80),  Thickness = 2.5 }, 0.15)
		tw(rs, { Color = Color3.fromRGB(255, 215, 0), Thickness = 3.5 }, 0.15)
	else
		tw(ls, { Color = Color3.fromRGB(80, 80, 80), Thickness = 2.5 }, 0.15)
		tw(rs, { Color = Color3.fromRGB(80, 80, 80), Thickness = 2.5 }, 0.15)
	end
end

-- ── применить видимость карточек ─────────────────────────
-- choicePanel.Visible НЕ трогаем — кнопки должны работать
local function applyPanelVisibility(visible, animate)
	panelVisible = visible
	local targetT = visible and 0 or 1
	local dur = animate and 0.25 or 0

	for _, card in ipairs({ leftCard, rightCard }) do
		if not card then continue end
		if animate then
			tw(card, { BackgroundTransparency = targetT }, dur)
		else
			card.BackgroundTransparency = targetT
		end
		for _, child in ipairs(card:GetDescendants()) do
			if child:IsA("TextLabel") then
				if animate then
					tw(child, { TextTransparency = targetT }, dur)
				else
					child.TextTransparency = targetT
				end
			elseif child:IsA("TextButton") then
				if animate then
					tw(child, { TextTransparency = targetT, BackgroundTransparency = targetT }, dur)
				else
					child.TextTransparency       = targetT
					child.BackgroundTransparency = targetT
				end
			elseif child:IsA("ImageLabel") then
				if animate then
					tw(child, { ImageTransparency = targetT }, dur)
				else
					child.ImageTransparency = targetT
				end
			elseif child:IsA("UIStroke") then
				if animate then
					tw(child, { Transparency = targetT }, dur)
				else
					child.Transparency = targetT
				end
			end
		end
	end

	if toggleBtn then
		toggleBtn.Text = visible and "👁 Скрыть" or "👁 Показать"
	end
end

-- ── waitForGui ────────────────────────────────────────────
local function waitForGui()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	-- ждём MainHUD до 20 секунд
	gui = pg:WaitForChild("MainHUD", 20)
	if not gui then
		warn("[ChoiceController] MainHUD не найден за 20 сек!")
		return false
	end

	choicePanel = gui:WaitForChild("ChoicePanel", 10)
	if not choicePanel then
		warn("[ChoiceController] ChoicePanel не найден!")
		return false
	end

	leftCard  = choicePanel:FindFirstChild("LeftCard")
	rightCard = choicePanel:FindFirstChild("RightCard")

	if leftCard then
		leftLabel = leftCard:FindFirstChild("Label")
		leftBtn   = leftCard:FindFirstChild("Button")
	end
	if rightCard then
		rightLabel = rightCard:FindFirstChild("Label")
		rightBtn   = rightCard:FindFirstChild("Button")
	end

	-- создаём/находим кнопку скрыть
	toggleBtn = ensureToggleBtn(gui)

	return true
end

-- ══════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════

function ChoiceController.Init()
	local ok = waitForGui()
	if not ok then return end

	-- Кнопка «Выбрать» — левая
	if leftBtn then
		leftBtn.MouseButton1Click:Connect(function()
			if not choiceEnabled then return end
			currentSide = Enums.Team.Left
			SubmitChoice:FireServer({ Side = Enums.Team.Left })
			refreshBorders()
		end)
		leftBtn.MouseEnter:Connect(function()
			if not choiceEnabled then return end
			tw(leftBtn, { BackgroundColor3 = Color3.fromRGB(220, 225, 255) }, 0.12)
		end)
		leftBtn.MouseLeave:Connect(function()
			tw(leftBtn, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.12)
		end)
	end

	-- Кнопка «Выбрать» — правая
	if rightBtn then
		rightBtn.MouseButton1Click:Connect(function()
			if not choiceEnabled then return end
			currentSide = Enums.Team.Right
			SubmitChoice:FireServer({ Side = Enums.Team.Right })
			refreshBorders()
		end)
		rightBtn.MouseEnter:Connect(function()
			if not choiceEnabled then return end
			tw(rightBtn, { BackgroundColor3 = Color3.fromRGB(255, 220, 210) }, 0.12)
		end)
		rightBtn.MouseLeave:Connect(function()
			tw(rightBtn, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.12)
		end)
	end

	-- Кнопка «Скрыть / Показать»
	if toggleBtn then
		toggleBtn.MouseButton1Click:Connect(function()
			applyPanelVisibility(not panelVisible, true)
		end)
		toggleBtn.MouseEnter:Connect(function()
			tw(toggleBtn, { BackgroundTransparency = 0.05 }, 0.12)
		end)
		toggleBtn.MouseLeave:Connect(function()
			tw(toggleBtn, { BackgroundTransparency = 0.25 }, 0.12)
		end)
	end
end

function ChoiceController.RevealChoiceA(text, color)
	if not choicePanel then return end
	choicePanel.Visible = true
	choiceEnabled       = false
	panelVisible        = true

	if toggleBtn then toggleBtn.Visible = false end

	applyPanelVisibility(true, false)

	if leftCard then
		leftCard.Visible  = true
		leftCard.Position = UDim2.new(-0.55, 0, 0, 0)
		leftCard.BackgroundTransparency = 0.6
		if leftLabel then leftLabel.Text = text end
		tw(leftCard, {
			Position               = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 0,
		}, 0.4, Enum.EasingStyle.Back)
	end
	if rightCard then
		rightCard.Visible = false
	end
end

function ChoiceController.RevealChoiceB(text, color)
	if not rightCard then return end
	rightCard.Visible = true
	if rightLabel then rightLabel.Text = text end

	rightCard.Position = UDim2.new(1.08, 0, 0, 0)
	rightCard.BackgroundTransparency = 0.6
	tw(rightCard, {
		Position               = UDim2.new(0.53, 0, 0, 0),
		BackgroundTransparency = 0,
	}, 0.4, Enum.EasingStyle.Back)
end

function ChoiceController.ShowFullChoices(data)
	if not choicePanel then return end
	choicePanel.Visible = true
	choiceEnabled       = true
	currentSide         = nil
	panelVisible        = true

	applyPanelVisibility(true, false)

	if leftCard then
		leftCard.Visible = true
		if leftLabel then leftLabel.Text = data.LeftText or "Left" end
	end
	if rightCard then
		rightCard.Visible = true
		if rightLabel then rightLabel.Text = data.RightText or "Right" end
	end

	refreshBorders()

	-- Показываем кнопку скрыть с анимацией
	if toggleBtn then
		toggleBtn.Text    = "👁 Скрыть"
		toggleBtn.Visible = true
		toggleBtn.BackgroundTransparency = 1
		tw(toggleBtn, { BackgroundTransparency = 0.25 }, 0.3)
	end
end

function ChoiceController.HideChoices()
	if not choicePanel then return end

	if leftCard and leftCard.Visible then
		tw(leftCard, {
			Position               = UDim2.new(-0.55, 0, 0, 0),
			BackgroundTransparency = 1,
		}, 0.3)
	end
	if rightCard and rightCard.Visible then
		tw(rightCard, {
			Position               = UDim2.new(1.08, 0, 0, 0),
			BackgroundTransparency = 1,
		}, 0.3)
	end

	task.delay(0.35, function()
		choicePanel.Visible = false
		choiceEnabled       = false
		currentSide         = nil
		panelVisible        = true
		if leftCard  then
			leftCard.Position  = UDim2.new(0, 0, 0, 0)
			leftCard.BackgroundTransparency = 0
		end
		if rightCard then
			rightCard.Position = UDim2.new(0.53, 0, 0, 0)
			rightCard.BackgroundTransparency = 0
		end
	end)

	if toggleBtn then
		tw(toggleBtn, { BackgroundTransparency = 1 }, 0.2)
		task.delay(0.25, function()
			toggleBtn.Visible = false
		end)
	end
end

return ChoiceController