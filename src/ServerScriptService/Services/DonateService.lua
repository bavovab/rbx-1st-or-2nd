-- ModuleScript: ServerScriptService/Services/DonateService.lua

local Players             = game:GetService("Players")
local MarketplaceService  = game:GetService("MarketplaceService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local DonateConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("DonateConfig"))
local Enums        = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local HUDMessage = Remotes:WaitForChild("HUDMessage")

local DonateService = {}

-- { [userId] = true } — у кого есть бомба на этот раунд
local pendingBombs = {}
-- { [userId] = usesLeft } — сколько использований осталось в текущем бою
local activeBombs  = {}

local PlayerStateService
local CombatService

-----------------------------------------------------------------------
-- Внутренние хелперы
-----------------------------------------------------------------------

local function getTemplate()
	local t = workspace:FindFirstChild(DonateConfig.BOMB_TOOL_NAME)
	if not t then
		warn("[DonateService] Tool '" .. DonateConfig.BOMB_TOOL_NAME .. "' не найден в Workspace!")
	end
	return t
end

local function giveBombTool(player)
	local template = getTemplate()
	if not template then return end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end

	-- Убираем старую если есть
	local old = backpack:FindFirstChild(DonateConfig.BOMB_TOOL_NAME)
		or (player.Character and player.Character:FindFirstChild(DonateConfig.BOMB_TOOL_NAME))
	if old then old:Destroy() end

	local clone = template:Clone()
	clone.Parent = backpack
	print(string.format("[DonateService] TeamBomb выдана %s", player.Name))
end

local function removeBombTool(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char     = player.Character

	if backpack then
		local w = backpack:FindFirstChild(DonateConfig.BOMB_TOOL_NAME)
		if w then w:Destroy() end
	end
	if char then
		local w = char:FindFirstChild(DonateConfig.BOMB_TOOL_NAME)
		if w then w:Destroy() end
	end
end

local function killEnemyTeam(player)
	local uid   = player.UserId
	local uses  = activeBombs[uid]
	if not uses or uses <= 0 then
		HUDMessage:FireClient(player, {
			Message = "💣 Бомба уже использована!",
			Color   = Color3.fromRGB(255,100,100),
		})
		return
	end

	-- Определяем команду игрока
	local allStates = PlayerStateService.GetAllStates()
	local myState   = allStates[uid]
	if not myState then return end

	local myTeam = myState.Team
	if not myTeam then
		HUDMessage:FireClient(player, {
			Message = "💣 Команда не определена!",
			Color   = Color3.fromRGB(255,100,100),
		})
		return
	end

	-- Определяем вражескую команду
	local enemyTeam
	if myTeam == Enums.Team.Left or myTeam == "Left" then
		enemyTeam = Enums.Team.Right
	else
		enemyTeam = Enums.Team.Left
	end

	-- Убиваем всех врагов
	local killed = 0
	for enemyUid, state in pairs(allStates) do
		if state.Team == enemyTeam
		or (enemyTeam == Enums.Team.Left  and state.Team == "Left")
		or (enemyTeam == Enums.Team.Right and state.Team == "Right") then
			local enemy = Players:GetPlayerByUserId(enemyUid)
			if enemy and enemy.Character then
				local hum = enemy.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hum.Health = 0
					killed += 1
				end
			end
		end
	end

	-- Списываем использование
	activeBombs[uid] = uses - 1
	removeBombTool(player)

	print(string.format("[DonateService] %s использовал TeamBomb. Убито: %d", player.Name, killed))

	HUDMessage:FireClient(player, {
		Message = "💣 БОМБА! Уничтожено " .. killed .. " врагов!",
		Color   = Color3.fromRGB(255,200,0),
	})

	-- Сообщение врагам
	for enemyUid, state in pairs(allStates) do
		if state.Team == enemyTeam
		or (enemyTeam == Enums.Team.Left  and state.Team == "Left")
		or (enemyTeam == Enums.Team.Right and state.Team == "Right") then
			local enemy = Players:GetPlayerByUserId(enemyUid)
			if enemy then
				HUDMessage:FireClient(enemy, {
					Message = "💀 Вас уничтожила командная бомба!",
					Color   = Color3.fromRGB(255,50,50),
				})
			end
		end
	end
end

-----------------------------------------------------------------------
-- Публичный API
-----------------------------------------------------------------------

function DonateService.Init(pss, cs)
	PlayerStateService = pss
	CombatService      = cs

	-- Обработка покупки
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		if receiptInfo.ProductId == DonateConfig.BOMB_PRODUCT_ID then
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if player then
				pendingBombs[receiptInfo.PlayerId] = true
				print(string.format("[DonateService] %s купил TeamBomb (pending)", player.Name))
				HUDMessage:FireClient(player, {
					Message = "💣 TeamBomb куплена! Выдадим в начале следующего боя.",
					Color   = Color3.fromRGB(255,220,50),
				})
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		-- Другие продукты — не трогаем
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Слушаем активацию Tool: когда игрок экипирует и "использует" бомбу
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			char.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and child.Name == DonateConfig.BOMB_TOOL_NAME then
					child.Activated:Connect(function()
						killEnemyTeam(player)
					end)
				end
			end)
		end)
	end)

	-- Для игроков которые уже в игре
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			char.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and child.Name == DonateConfig.BOMB_TOOL_NAME then
					child.Activated:Connect(function()
						killEnemyTeam(player)
					end)
				end
			end)
		end
	end

	print("[DonateService] Initialized.")
end

-- Вызывается из CombatService.InitializeHP — выдаёт бомбы тем у кого pending
function DonateService.GrantPendingBombs(playerList)
	for _, player in ipairs(playerList) do
		local uid = player.UserId
		if pendingBombs[uid] then
			pendingBombs[uid] = nil
			activeBombs[uid]  = DonateConfig.BOMB_USES
			giveBombTool(player)
			HUDMessage:FireClient(player, {
				Message = "💣 TeamBomb активна! Нажми чтобы уничтожить врагов.",
				Color   = Color3.fromRGB(255,220,0),
			})
		end
	end
end

-- Вызывается из CombatService.EndRound — чистим активные бомбы
function DonateService.ClearActiveBombs(playerList)
	for _, player in ipairs(playerList or {}) do
		activeBombs[player.UserId] = nil
		removeBombTool(player)
	end
	print("[DonateService] Active bombs cleared.")
end

-- Проверка: есть ли у игрока активная бомба
function DonateService.HasActiveBomb(userId)
	return (activeBombs[userId] or 0) > 0
end

return DonateService