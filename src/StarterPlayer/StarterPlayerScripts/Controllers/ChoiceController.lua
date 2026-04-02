-- ChoiceController.lua
-- Displays the two choice cards and lets the player submit their side.

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UserInputSvc  = game:GetService("UserInputService")
local UIConfig      = require(game.ReplicatedStorage.Config.UIConfig)
local Enums         = require(game.ReplicatedStorage.Shared.Enums)
local Effects       = require(script.Parent.EffectsController)

local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

local Remotes       = game.ReplicatedStorage.Remotes

local ChoiceController = {}

local _gui
local _leftCard
local _rightCard
local _leftLabel
local _rightLabel
local _selectedSide = nil
local _choiceOpen   = false

local CARD_SIZE_NORMAL   = UDim2.new(0.3, 0, 0.5, 0)
local CARD_SIZE_SELECTED = UDim2.new(0.33, 0, 0.54, 0)

local function MakeChoiceGui()
	if _gui then _gui:Destroy() end

	_gui = Instance.new("ScreenGui")
	_gui.Name           = "ChoiceGui"
	_gui.ResetOnSpawn   = false
	_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_gui.IgnoreGuiInset = false
	_gui.Parent         = PlayerGui

	-- Left card
	_leftCard = Instance.new("TextButton")
	_leftCard.Name               = "LeftCard"
	_leftCard.Size               = CARD_SIZE_NORMAL
	_leftCard.Position           = UDim2.new(0.08, 0, 0.22, 0)
	_leftCard.BackgroundColor3   = UIConfig.LEFT_COLOR_DEFAULT
	_leftCard.BackgroundTransparency = 0.2
	_leftCard.BorderSizePixel    = 0
	_leftCard.Text               = ""
	_leftCard.Visible            = false
	_leftCard.Parent             = _gui

	local lCorner = Instance.new("UICorner")
	lCorner.CornerRadius = UDim.new(0, 12)
	lCorner.Parent = _leftCard

	_leftLabel = Instance.new("TextLabel")
	_leftLabel.Name               = "Label"
	_leftLabel.Size               = UDim2.new(1, -16, 1, 0)
	_leftLabel.Position           = UDim2.new(0, 8, 0, 0)
	_leftLabel.BackgroundTransparency = 1
	_leftLabel.Font               = UIConfig.BANNER_FONT
	_leftLabel.TextSize           = 32
	_leftLabel.TextColor3         = UIConfig.TEXT_PRIMARY
	_leftLabel.TextStrokeTransparency = 0.5
	_leftLabel.TextXAlignment     = Enum.TextXAlignment.Center
	_leftLabel.TextWrapped        = true
	_leftLabel.Text               = "???"
	_leftLabel.Parent             = _leftCard

	local leftHint = Instance.new("TextLabel")
	leftHint.Name               = "Hint"
	leftHint.Size               = UDim2.new(1, 0, 0, 28)
	leftHint.Position           = UDim2.new(0, 0, 1, -32)
	leftHint.BackgroundTransparency = 1
	leftHint.Font               = UIConfig.BODY_FONT
	leftHint.TextSize           = 16
	leftHint.TextColor3         = UIConfig.TEXT_SECONDARY
	leftHint.Text               = "Press [A] or click"
	leftHint.Parent             = _leftCard

	-- Right card
	_rightCard = Instance.new("TextButton")
	_rightCard.Name               = "RightCard"
	_rightCard.Size               = CARD_SIZE_NORMAL
	_rightCard.Position           = UDim2.new(0.62, 0, 0.22, 0)
	_rightCard.BackgroundColor3   = UIConfig.RIGHT_COLOR_DEFAULT
	_rightCard.BackgroundTransparency = 0.2
	_rightCard.BorderSizePixel    = 0
	_rightCard.Text               = ""
	_rightCard.Visible            = false
	_rightCard.Parent             = _gui

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 12)
	rCorner.Parent = _rightCard

	_rightLabel = Instance.new("TextLabel")
	_rightLabel.Name               = "Label"
	_rightLabel.Size               = UDim2.new(1, -16, 1, 0)
	_rightLabel.Position           = UDim2.new(0, 8, 0, 0)
	_rightLabel.BackgroundTransparency = 1
	_rightLabel.Font               = UIConfig.BANNER_FONT
	_rightLabel.TextSize           = 32
	_rightLabel.TextColor3         = UIConfig.TEXT_PRIMARY
	_rightLabel.TextStrokeTransparency = 0.5
	_rightLabel.TextXAlignment     = Enum.TextXAlignment.Center
	_rightLabel.TextWrapped        = true
	_rightLabel.Text               = "???"
	_rightLabel.Parent             = _rightCard

	local rightHint = Instance.new("TextLabel")
	rightHint.Name               = "Hint"
	rightHint.Size               = UDim2.new(1, 0, 0, 28)
	rightHint.Position           = UDim2.new(0, 0, 1, -32)
	rightHint.BackgroundTransparency = 1
	rightHint.Font               = UIConfig.BODY_FONT
	rightHint.TextSize           = 16
	rightHint.TextColor3         = UIConfig.TEXT_SECONDARY
	rightHint.Text               = "Press [D] or click"
	rightHint.Parent             = _rightCard

	-- Click handlers
	_leftCard.Activated:Connect(function()
		if _choiceOpen then
			ChoiceController.SubmitChoice(Enums.Team.Left)
		end
	end)
	_rightCard.Activated:Connect(function()
		if _choiceOpen then
			ChoiceController.SubmitChoice(Enums.Team.Right)
		end
	end)
end

local function HighlightSide(side)
	_selectedSide = side
	if side == Enums.Team.Left then
		TweenService:Create(_leftCard,  TweenInfo.new(0.2), { Size = CARD_SIZE_SELECTED }):Play()
		TweenService:Create(_rightCard, TweenInfo.new(0.2), { Size = CARD_SIZE_NORMAL }):Play()
		TweenService:Create(_leftCard,  TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(_rightCard, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
	elseif side == Enums.Team.Right then
		TweenService:Create(_rightCard, TweenInfo.new(0.2), { Size = CARD_SIZE_SELECTED }):Play()
		TweenService:Create(_leftCard,  TweenInfo.new(0.2), { Size = CARD_SIZE_NORMAL }):Play()
		TweenService:Create(_rightCard, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(_leftCard,  TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
	end
end

function ChoiceController.SubmitChoice(side)
	if not _choiceOpen then return end
	HighlightSide(side)
	Remotes.SubmitChoice:FireServer(side)
end

-- Show a card (Left or Right) being revealed
function ChoiceController.RevealCard(side, data)
	if not _gui then MakeChoiceGui() end
	if side == "Left" then
		_leftCard.BackgroundColor3 = data.Color or UIConfig.LEFT_COLOR_DEFAULT
		_leftLabel.Text = data.Text or "???"
		_leftCard.Visible = true
		Effects.SlideIn(_leftCard, "Left", 0.4)
	elseif side == "Right" then
		_rightCard.BackgroundColor3 = data.Color or UIConfig.RIGHT_COLOR_DEFAULT
		_rightLabel.Text = data.Text or "???"
		_rightCard.Visible = true
		Effects.SlideIn(_rightCard, "Right", 0.4)
	end
end

function ChoiceController.OpenChoice()
	_choiceOpen   = true
	_selectedSide = nil
	-- Reset card sizes
	if _leftCard  then _leftCard.Size  = CARD_SIZE_NORMAL; _leftCard.BackgroundTransparency  = 0.2 end
	if _rightCard then _rightCard.Size = CARD_SIZE_NORMAL; _rightCard.BackgroundTransparency = 0.2 end
end

function ChoiceController.CloseChoice()
	_choiceOpen = false
end

function ChoiceController.HideCards()
	_choiceOpen = false
	if _leftCard  then _leftCard.Visible  = false end
	if _rightCard then _rightCard.Visible = false end
	_selectedSide = nil
end

function ChoiceController.Init()
	MakeChoiceGui()

	-- Keyboard input for choice
	UserInputSvc.InputBegan:Connect(function(input, processed)
		if processed or not _choiceOpen then return end
		if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
			ChoiceController.SubmitChoice(Enums.Team.Left)
		elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
			ChoiceController.SubmitChoice(Enums.Team.Right)
		end
	end)
end

return ChoiceController