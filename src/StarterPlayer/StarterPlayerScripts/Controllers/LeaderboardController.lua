local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputSvc = game:GetService("UserInputService")

local UIConfig     = require(game.ReplicatedStorage.Config.UIConfig)
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

local RemotesFolder     = game.ReplicatedStorage:WaitForChild("Remotes")
local RemoteLeaderboard = RemotesFolder:WaitForChild("LeaderboardUpdate")

local LeaderboardController = {}

local _gui
local _mainFrame
local _scrollFrame
local _rowPool   = {}
local _visible   = true

local PANEL_WIDTH = 260
local ROW_HEIGHT  = 36
local MAX_ROWS    = 10
local HEADER_H    = 44
local COL_H       = 22

local COL_RANK_W  = 30
local COL_NAME_W  = 110
local COL_WINS_W  = 38
local COL_KILLS_W = 38
local COL_COINS_W = 44

local RANK_COLORS = {
	[1] = Color3.fromRGB(255, 215, 0),
	[2] = Color3.fromRGB(192, 192, 192),
	[3] = Color3.fromRGB(180, 120, 50),
}

local TOTAL_H = HEADER_H + COL_H + ROW_HEIGHT * MAX_ROWS + 8

local function MakeLabel(parent, name, text, size, pos, font, textSize, color, align)
	local lbl = Instance.new("TextLabel")
	lbl.Name               = name
	lbl.Text               = text
	lbl.Size               = size
	lbl.Position           = pos
	lbl.BackgroundTransparency = 1
	lbl.Font               = font or UIConfig.BODY_FONT
	lbl.TextSize           = textSize or 14
	lbl.TextColor3         = color or UIConfig.TEXT_PRIMARY
	lbl.TextXAlignment     = align or Enum.TextXAlignment.Left
	lbl.TextTruncate       = Enum.TextTruncate.AtEnd
	lbl.ZIndex             = 5
	lbl.Parent             = parent
	return lbl
end

local function MakeFrame(parent, name, size, pos, color, trans)
	local f = Instance.new("Frame")
	f.Name               = name
	f.Size               = size
	f.Position           = pos
	f.BackgroundColor3   = color or UIConfig.BACKGROUND_PANEL
	f.BackgroundTransparency = trans or 0
	f.BorderSizePixel    = 0
	f.ZIndex             = 4
	f.Parent             = parent
	return f
end

local function BuildGUI()
	if _gui then _gui:Destroy() end
	_rowPool = {}

	_gui = Instance.new("ScreenGui")
	_gui.Name           = "LeaderboardGui"
	_gui.ResetOnSpawn   = false
	_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_gui.DisplayOrder   = 5
	_gui.IgnoreGuiInset = false
	_gui.Parent         = PlayerGui

	-- Основная панель
	_mainFrame = Instance.new("Frame")
	_mainFrame.Name               = "MainFrame"
	_mainFrame.Size               = UDim2.new(0, PANEL_WIDTH, 0, TOTAL_H)
	_mainFrame.Position           = UDim2.new(1, -PANEL_WIDTH - 8, 0, 52)
	_mainFrame.AnchorPoint        = Vector2.new(0, 0)
	_mainFrame.BackgroundColor3   = Color3.fromRGB(10, 10, 18)
	_mainFrame.BackgroundTransparency = 0.2
	_mainFrame.BorderSizePixel    = 0
	_mainFrame.ZIndex             = 4
	_mainFrame.Parent             = _gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = _mainFrame

	-- Заголовок
	local header = Instance.new("Frame")
	header.Name               = "Header"
	header.Size               = UDim2.new(1, 0, 0, HEADER_H)
	header.Position           = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3   = Color3.fromRGB(20, 20, 38)
	header.BackgroundTransparency = 0
	header.BorderSizePixel    = 0
	header.ZIndex             = 5
	header.Parent             = _mainFrame

	local hCorner = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, 8)
	hCorner.Parent = header

	MakeLabel(header, "Title", "🏆  LEADERBOARD",
		UDim2.new(1, -60, 1, 0), UDim2.new(0, 10, 0, 0),
		UIConfig.BANNER_FONT, 15,
		Color3.fromRGB(255, 215, 0), Enum.TextXAlignment.Left)

	MakeLabel(header, "Hint", "[Tab]",
		UDim2.new(0, 46, 1, 0), UDim2.new(1, -50, 0, 0),
		UIConfig.BODY_FONT, 12,
		UIConfig.TEXT_SECONDARY, Enum.TextXAlignment.Right)

	-- Заголовок колонок
	local colRow = Instance.new("Frame")
	colRow.Name               = "ColHeader"
	colRow.Size               = UDim2.new(1, 0, 0, COL_H)
	colRow.Position           = UDim2.new(0, 0, 0, HEADER_H)
	colRow.BackgroundColor3   = Color3.fromRGB(15, 15, 28)
	colRow.BackgroundTransparency = 0
	colRow.BorderSizePixel    = 0
	colRow.ZIndex             = 5
	colRow.Parent             = _mainFrame

	local x = 6
	MakeLabel(colRow, "C1", "#",    UDim2.new(0, COL_RANK_W,  1,0), UDim2.new(0, x, 0,0), UIConfig.BODY_FONT, 12, UIConfig.TEXT_SECONDARY, Enum.TextXAlignment.Center) x = x + COL_RANK_W
	MakeLabel(colRow, "C2", "NAME", UDim2.new(0, COL_NAME_W,  1,0), UDim2.new(0, x, 0,0), UIConfig.BODY_FONT, 12, UIConfig.TEXT_SECONDARY, Enum.TextXAlignment.Left)   x = x + COL_NAME_W
	MakeLabel(colRow, "C3", "W",    UDim2.new(0, COL_WINS_W,  1,0), UDim2.new(0, x, 0,0), UIConfig.BODY_FONT, 12, Color3.fromRGB(80,220,120), Enum.TextXAlignment.Center) x = x + COL_WINS_W
	MakeLabel(colRow, "C4", "K",    UDim2.new(0, COL_KILLS_W, 1,0), UDim2.new(0, x, 0,0), UIConfig.BODY_FONT, 12, Color3.fromRGB(220,100,80), Enum.TextXAlignment.Center) x = x + COL_KILLS_W
	MakeLabel(colRow, "C5", "💰",   UDim2.new(0, COL_COINS_W, 1,0), UDim2.new(0, x, 0,0), UIConfig.BODY_FONT, 12, Color3.fromRGB(255,200,50), Enum.TextXAlignment.Center)

	-- Список строк
	_scrollFrame = Instance.new("ScrollingFrame")
	_scrollFrame.Name                 = "List"
	_scrollFrame.Size                 = UDim2.new(1, 0, 1, -(HEADER_H + COL_H + 4))
	_scrollFrame.Position             = UDim2.new(0, 0, 0, HEADER_H + COL_H + 4)
	_scrollFrame.BackgroundTransparency = 1
	_scrollFrame.BorderSizePixel      = 0
	_scrollFrame.ScrollBarThickness   = 3
	_scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 110)
	_scrollFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
	_scrollFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
	_scrollFrame.ZIndex               = 5
	_scrollFrame.Parent               = _mainFrame

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding   = UDim.new(0, 2)
	layout.Parent    = _scrollFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft   = UDim.new(0, 3)
	padding.PaddingRight  = UDim.new(0, 3)
	padding.PaddingTop    = UDim.new(0, 2)
	padding.Parent        = _scrollFrame

	-- Заглушка пока нет данных
	local empty = Instance.new("TextLabel")
	empty.Name               = "EmptyLabel"
	empty.Size               = UDim2.new(1, 0, 0, 40)
	empty.BackgroundTransparency = 1
	empty.Text               = "Waiting for data..."
	empty.Font               = UIConfig.BODY_FONT
	empty.TextSize           = 13
	empty.TextColor3         = UIConfig.TEXT_SECONDARY
	empty.ZIndex             = 5
	empty.LayoutOrder        = 999
	empty.Parent             = _scrollFrame
end

local function GetOrCreateRow(index)
	if _rowPool[index] then
		return _rowPool[index]
	end

	local row = Instance.new("Frame")
	row.Name               = "Row_" .. index
	row.Size               = UDim2.new(1, -2, 0, ROW_HEIGHT)
	row.BackgroundColor3   = index % 2 == 0
		and Color3.fromRGB(22, 22, 36)
		or  Color3.fromRGB(18, 18, 30)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel    = 0
	row.LayoutOrder        = index
	row.ZIndex             = 6
	row.Parent             = _scrollFrame

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 4)
	rc.Parent = row

	-- Подсветка (скрыта по умолчанию)
	local hl = Instance.new("Frame")
	hl.Name               = "Highlight"
	hl.Size               = UDim2.new(1, 0, 1, 0)
	hl.BackgroundColor3   = Color3.fromRGB(80, 160, 255)
	hl.BackgroundTransparency = 1
	hl.BorderSizePixel    = 0
	hl.ZIndex             = 6
	hl.Parent             = row
	local hlc = Instance.new("UICorner")
	hlc.CornerRadius = UDim.new(0, 4)
	hlc.Parent = hl

	local x = 4
	MakeLabel(row, "Rank",  "", UDim2.new(0, COL_RANK_W,  1,-4), UDim2.new(0, x, 0,2), UIConfig.BANNER_FONT, 14, UIConfig.TEXT_SECONDARY, Enum.TextXAlignment.Center) x = x + COL_RANK_W
	MakeLabel(row, "Name",  "", UDim2.new(0, COL_NAME_W,  1,-4), UDim2.new(0, x, 0,2), UIConfig.BODY_FONT,   13, UIConfig.TEXT_PRIMARY,    Enum.TextXAlignment.Left)   x = x + COL_NAME_W
	MakeLabel(row, "Wins",  "", UDim2.new(0, COL_WINS_W,  1,-4), UDim2.new(0, x, 0,2), UIConfig.BODY_FONT,   13, Color3.fromRGB(80,220,120), Enum.TextXAlignment.Center) x = x + COL_WINS_W
	MakeLabel(row, "Kills", "", UDim2.new(0, COL_KILLS_W, 1,-4), UDim2.new(0, x, 0,2), UIConfig.BODY_FONT,   13, Color3.fromRGB(220,100,80), Enum.TextXAlignment.Center) x = x + COL_KILLS_W
	MakeLabel(row, "Coins", "", UDim2.new(0, COL_COINS_W, 1,-4), UDim2.new(0, x, 0,2), UIConfig.BODY_FONT,   13, Color3.fromRGB(255,200,50), Enum.TextXAlignment.Center)

	_rowPool[index] = row
	return row
end

local function UpdateDisplay(data)
	-- Убираем заглушку
	local empty = _scrollFrame:FindFirstChild("EmptyLabel")
	if empty then empty.Visible = (#data == 0) end

	-- Скрываем все строки
	for _, row in ipairs(_rowPool) do
		row.Visible = false
	end

	for i, entry in ipairs(data) do
		if i > MAX_ROWS then break end
		local row = GetOrCreateRow(i)
		row.Visible = true

		local isMe      = (entry.Name == LocalPlayer.Name)
		local rankColor = RANK_COLORS[i] or UIConfig.TEXT_SECONDARY

		local hl = row:FindFirstChild("Highlight")
		if hl then
			hl.BackgroundTransparency = isMe and 0.8 or 1
		end

		local rankLbl = row:FindFirstChild("Rank")
		if rankLbl then
			if i == 1 then rankLbl.Text = "🥇"
			elseif i == 2 then rankLbl.Text = "🥈"
			elseif i == 3 then rankLbl.Text = "🥉"
			else rankLbl.Text = tostring(i)
			end
			rankLbl.TextColor3 = rankColor
		end

		local nameLbl = row:FindFirstChild("Name")
		if nameLbl then
			nameLbl.Text       = entry.Name
			nameLbl.TextColor3 = isMe and Color3.fromRGB(120, 210, 255) or UIConfig.TEXT_PRIMARY
			nameLbl.Font       = isMe and UIConfig.BANNER_FONT or UIConfig.BODY_FONT
		end

		local wLbl = row:FindFirstChild("Wins")
		if wLbl then wLbl.Text = tostring(entry.Wins) end

		local kLbl = row:FindFirstChild("Kills")
		if kLbl then kLbl.Text = tostring(entry.Kills) end

		local cLbl = row:FindFirstChild("Coins")
		if cLbl then cLbl.Text = tostring(entry.Coins) end
	end
end

local function SetVisible(v)
	_visible = v
	if not _mainFrame then return end
	local showPos = UDim2.new(1, -PANEL_WIDTH - 8, 0, 52)
	local hidePos = UDim2.new(1, 8, 0, 52)
	TweenService:Create(_mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		Position = _visible and showPos or hidePos
	}):Play()
end

function LeaderboardController.Init()
	BuildGUI()

	RemoteLeaderboard.OnClientEvent:Connect(function(data)
		UpdateDisplay(data)
	end)

	UserInputSvc.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Tab then
			SetVisible(not _visible)
		end
	end)

	-- Показываем себя сразу с пустыми данными
	task.spawn(function()
		task.wait(2)
		-- Если сервер ещё не прислал данные — показываем хотя бы себя
		local ls = LocalPlayer:FindFirstChild("leaderstats")
		if ls then
			local wins  = ls:FindFirstChild("Wins")
			local kills = ls:FindFirstChild("Kills")
			local coins = ls:FindFirstChild("Coins")
			UpdateDisplay({{
				Name   = LocalPlayer.Name,
				UserId = LocalPlayer.UserId,
				Wins   = wins  and wins.Value  or 0,
				Kills  = kills and kills.Value or 0,
				Coins  = coins and coins.Value or 0,
			}})
		end
	end)
end

return LeaderboardController