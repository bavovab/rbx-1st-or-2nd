-- ModuleScript: StarterPlayer/StarterPlayerScripts/Controllers/ChoiceController
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local UIConfig  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("UIConfig"))
local Enums     = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local SubmitChoice = Remotes:WaitForChild("SubmitChoice")

local ChoiceController = {}

-- ── ссылки на GUI ────────────────────────────────────────
local gui, choicePanel, leftCard, rightCard
local leftLabel, rightLabel, leftBtn, rightBtn, toggleBtn

-- ── состояние ────────────────────────────────────────────
local currentSide   = nil   -- выбранная сторона (сохраняется даже при скрытии)
local choiceEnabled = false -- фаза DarkChoice активна
local panelVisible  = true  -- визуальная видимость карточек (toggle)

-- ── тween-хелпер ─────────────────────────────────────────
local function tw(inst, props, t, style, dir)
	TweenService:Create(
		inst,
		TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
		props
	):Play()
end

-- ── обновить рамки по текущему выбору ────────────────────
local function refreshBorders()
	if not leftCard or not rightCard then return end
	local ls = leftCard:FindFirstChild("Border")
	local rs = rightCard:FindFirstChild("Border")
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

-- ── скрыть / показать карточки (кнопка-тогл) ─────────────
-- ВАЖНО: choicePanel.Visible остаётся true —
--        это нужно, чтобы кнопки и логика выбора работали.
--        Мы просто делаем карточки прозрачными.
local function applyPanelVisibility(visible, animate)
	panelVisible = visible
	local targetT = visible and 0 or 1
	local dur     = animate and 0.25 or 0

	local targets = { leftCard, rightCard }
	for _, card in ipairs(targets) do
		if card then
			if animate then
				tw(card, { BackgroundTransparency = targetT }, dur)
				-- дочерние элементы
				for _, child in ipairs(card:GetDescendants()) do
					if child:IsA("TextLabel") or child:IsA("TextButton") then
						tw(child, { TextTransparency       = targetT }, dur)
						tw(child, { BackgroundTransparency = child:IsA("TextButton") and targetT or 1 }, dur)
					elseif child:IsA("ImageLabel") then
						tw(child, { ImageTransparency = targetT }, dur)
					elseif child:IsA("UIStroke") then
						tw(child, { Transparency = targetT }, dur)
					end
				end
			else
				card.BackgroundTransparency = targetT
				for _, child in ipairs(card:GetDescendants()) do
					if child:IsA("TextLabel") or child:IsA("TextButton") then
						child.TextTransparency       = targetT
						if child:IsA("TextButton") then
							child.BackgroundTransparency = targetT
						end
					elseif child:IsA("ImageLabel") then
						child.ImageTransparency = targetT
					elseif child:IsA("UIStroke") then
						child.Transparency = targetT
					end
				end
			end
		end
	end

	-- Обновляем текст кнопки-тогла
	if toggleBtn then
		toggleBtn.Text = visible and "👁 Скрыть" or "👁 Показать"
	end
end

-- ── инициализация ─────────────────────────────────────────
local function waitForGui()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = pg:WaitForChild("MainHUD", 15)
	if not gui then warn("[ChoiceController] MainHUD не найден"); return end

	choicePanel = gui:WaitForChild("ChoicePanel")
	leftCard    = choicePanel:FindFirstChild("LeftCard")
	rightCard   = choicePanel:FindFirstChild("RightCard")
	toggleBtn   = gui:FindFirstChild("ToggleChoiceBtn")

	if leftCard then
		leftLabel = leftCard:FindFirstChild("Label")
		leftBtn   = leftCard:FindFirstChild("Button")
	end
	if rightCard then
		rightLabel = rightCard:FindFirstChild("Label")
		rightBtn   = rightCard:FindFirstChild("Button")
	end
end

function ChoiceController.Init()
	waitForGui()

	-- Кнопка Выбрать Левую
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

	-- Кнопка Выбрать Правую
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

	-- Кнопка Скрыть/Показать
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

-- ── RevealChoiceA: показываем только левую карточку ───────
function ChoiceController.RevealChoiceA(text, color)
	if not choicePanel then return end
	choicePanel.Visible = true
	choiceEnabled       = false
	panelVisible        = true

	if toggleBtn then toggleBtn.Visible = false end

	if leftCard then
		leftCard.Visible = true
		applyPanelVisibility(true, false)  -- сбросить прозрачности
		if leftLabel then leftLabel.Text = text end
		-- анимация появления левой карточки
		leftCard.Position = UDim2.new(-0.55, 0, 0, 0)
		leftCard.BackgroundTransparency = 0.6
		tw(leftCard, {
			Position             = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 0,
		}, 0.4, Enum.EasingStyle.Back)
	end
	if rightCard then
		rightCard.Visible = false
	end
end

-- ── RevealChoiceB: показываем правую карточку ─────────────
function ChoiceController.RevealChoiceB(text, color)
	if not rightCard then return end
	rightCard.Visible = true
	if rightLabel then rightLabel.Text = text end

	-- анимация появления правой карточки
	rightCard.Position = UDim2.new(1.08, 0, 0, 0)
	rightCard.BackgroundTransparency = 0.6
	tw(rightCard, {
		Position             = UDim2.new(0.53, 0, 0, 0),
		BackgroundTransparency = 0,
	}, 0.4, Enum.EasingStyle.Back)
end

-- ── ShowFullChoices: фаза DarkChoice ──────────────────────
function ChoiceController.ShowFullChoices(data)
	if not choicePanel then return end
	choicePanel.Visible = true
	choiceEnabled       = true
	currentSide         = nil
	panelVisible        = true

	-- убедимся что карточки полностью видимы и сброшены
	applyPanelVisibility(true, false)

	if leftCard then
		leftCard.Visible = true
		if leftLabel then leftLabel.Text = data.LeftText or "Left"  end
	end
	if rightCard then
		rightCard.Visible = true
		if rightLabel then rightLabel.Text = data.RightText or "Right" end
	end

	refreshBorders()

	-- Показываем кнопку скрыть
	if toggleBtn then
		toggleBtn.Visible = true
		toggleBtn.Text    = "👁 Скрыть"
		toggleBtn.BackgroundTransparency = 1
		tw(toggleBtn, { BackgroundTransparency = 0.25 }, 0.3)
	end
end

-- ── HideChoices: конец фазы выбора ────────────────────────
function ChoiceController.HideChoices()
	if not choicePanel then return end

	-- Анимированное скрытие
	if leftCard and leftCard.Visible then
		tw(leftCard,  { Position = UDim2.new(-0.55, 0, 0, 0), BackgroundTransparency = 1 }, 0.3)
	end
	if rightCard and rightCard.Visible then
		tw(rightCard, { Position = UDim2.new(1.08, 0, 0, 0),  BackgroundTransparency = 1 }, 0.3)
	end

	task.delay(0.35, function()
		choicePanel.Visible = false
		choiceEnabled       = false
		currentSide         = nil
		panelVisible        = true

		-- сброс позиций для следующего раза
		if leftCard  then leftCard.Position  = UDim2.new(0, 0, 0, 0) end
		if rightCard then rightCard.Position = UDim2.new(0.53, 0, 0, 0) end
	end)

	if toggleBtn then
		tw(toggleBtn, { BackgroundTransparency = 1 }, 0.2)
		task.delay(0.25, function()
			toggleBtn.Visible = false
		end)
	end
end

return ChoiceController