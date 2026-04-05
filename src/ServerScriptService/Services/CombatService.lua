-- ModuleScript: ServerScriptService/Services/CombatService.lua

local DonateService -- инжектируется через SetDonateService
local DataService   -- инжектируется через SetDataService

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums        = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local Utility      = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utility"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CombatConfig"))

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local HUDMessage = Remotes:WaitForChild("HUDMessage")

local PlayerStateService

local CombatService = {}

local combatData  = {}
local diedInRound = {}
local diedConns   = {}

-----------------------------------------------------------------------
-- Инжекция зависимостей
-----------------------------------------------------------------------

function CombatService.SetDonateService(ds)
	DonateService = ds
end

function CombatService.SetDataService(ds)
	DataService = ds
end

-----------------------------------------------------------------------
-- Шаблон оружия
-----------------------------------------------------------------------

local function getWeaponTemplate()
	local template = workspace:FindFirstChild("ClassicSword")
	if not template then
		warn("[CombatService] ClassicSword не найден в Workspace!")
		return nil
	end
	return template
end

-----------------------------------------------------------------------
-- Выдача / изъятие оружия
-----------------------------------------------------------------------

local function giveWeapon(player)
	local template = getWeaponTemplate()
	if not template then return end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local char     = player.Character

	if backpack then
		local old = backpack:FindFirstChild("ClassicSword")
		if old then old:Destroy() end
	end
	if char then
		local old = char:FindFirstChild("ClassicSword")
		if old then old:Destroy() end
	end

	if backpack then
		local clone = template:Clone()
		clone.Parent = backpack
		print(string.format("[CombatService] ClassicSword выдан %s", player.Name))
	else
		warn(string.format("[CombatService] Backpack не найден у %s", player.Name))
	end
end

local function removeWeapon(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local char     = player.Character

	if backpack then
		local w = backpack:FindFirstChild("ClassicSword")
		if w then w:Destroy() end
	end
	if char then
		local w = char:FindFirstChild("ClassicSword")
		if w then w:Destroy() end
	end
end

-----------------------------------------------------------------------
-- Смерть в бою
-----------------------------------------------------------------------

local function onPlayerDiedInBattle(player)
	local uid = player.UserId
	if not combatData[uid] then return end

	diedInRound[uid] = true
	combatData[uid]  = nil

	print(string.format("[CombatService] %s погиб в бою.", player.Name))

	if PlayerStateService then
		PlayerStateService.SetAlive(player, false)
	end

	removeWeapon(player)

	HUDMessage:FireClient(player, {
		Message = "💀 Ты выбыл! Ожидай результатов...",
		Color   = Color3.fromRGB(255, 100, 100),
	})

	task.delay(1.5, function()
		if not player or not player.Parent then return end

		local lobby       = workspace:FindFirstChild("Lobby")
		local spawnPoints = lobby and lobby:FindFirstChild("SpawnPoints")
		local spawnList   = spawnPoints and spawnPoints:GetChildren()
		local spawn       = spawnList and spawnList[1]

		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")

			if hum and hum.Health <= 0 then
				player:LoadCharacter()
				local newChar = player.CharacterAdded:Wait()
				task.wait(0.1)
				local newHRP = newChar:FindFirstChild("HumanoidRootPart")
				if newHRP and spawn then
					newHRP.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
				end
			else
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp and spawn then
					hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
				end
			end
		end
	end)
end

local function setupDiedConnection(player)
	local uid = player.UserId

	if diedConns[uid] then
		diedConns[uid]:Disconnect()
		diedConns[uid] = nil
	end

	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	diedConns[uid] = hum.Died:Connect(function()
		onPlayerDiedInBattle(player)
	end)
end

-----------------------------------------------------------------------
-- Урон
-----------------------------------------------------------------------

local function applyDamage(attackerUserId, targetPlayer, damage)
	local data = combatData[targetPlayer.UserId]
	if not data then return end

	data.hp = math.max(0, data.hp - damage)

	if PlayerStateService then
		PlayerStateService.SetHP(targetPlayer, data.hp)
		local attacker = Players:GetPlayerByUserId(attackerUserId)
		if attacker then
			PlayerStateService.AddDamage(attacker, damage)
		end
	end

	HUDMessage:FireClient(targetPlayer, {
		Message = "❤️ HP: " .. data.hp .. " / " .. CombatConfig.MAX_HP,
		Color   = Color3.fromRGB(255, 80, 80),
	})

	local attacker = Players:GetPlayerByUserId(attackerUserId)
	if attacker then
		HUDMessage:FireClient(attacker, {
			Message = "⚔️ Hit! -" .. damage .. " HP",
			Color   = Color3.fromRGB(255, 200, 50),
		})
	end

	print(string.format(
		"[CombatService] %d -> %s: -%d HP (осталось %d)",
		attackerUserId, targetPlayer.Name, damage, data.hp
	))

	if data.hp <= 0 then
		-- Записываем убийство атакующему
		if DataService and attacker then
			DataService.AddKill(attacker, 1)
		end

		local char = targetPlayer.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = 0 end
		end
	end
end

-----------------------------------------------------------------------
-- Публичный API
-----------------------------------------------------------------------

function CombatService.Init(pss, ts)
	PlayerStateService = pss
end

function CombatService.InitializeHP(playerList)
	combatData  = {}
	diedInRound = {}

	for uid, conn in pairs(diedConns) do
		conn:Disconnect()
	end
	diedConns = {}

	for _, player in ipairs(playerList) do
		combatData[player.UserId] = {
			hp         = CombatConfig.MAX_HP,
			lastAttack = 0,
			team       = nil,
		}

		if PlayerStateService then
			PlayerStateService.SetAlive(player, true)
			PlayerStateService.SetHP(player, CombatConfig.MAX_HP)
		end

		giveWeapon(player)
		setupDiedConnection(player)

		print(string.format("[CombatService] %s инициализирован: HP=%d", player.Name, CombatConfig.MAX_HP))
	end

	-- Выдаём бомбы донатерам после giveWeapon для всех
	if DonateService then
		DonateService.GrantPendingBombs(playerList)
	end
end

function CombatService.ProcessAction(player, payload)
	local uid  = player.UserId
	local data = combatData[uid]
	if not data then return end

	local action = payload.Action

	if action == Enums.CombatAction.Melee or action == "Melee" then
		local now = os.clock()
		if now - data.lastAttack < CombatConfig.ATTACK_COOLDOWN then return end
		data.lastAttack = now

		local targetId = payload.TargetId
		if not targetId then return end

		local targetPlayer = Players:GetPlayerByUserId(targetId)
		if not targetPlayer then return end

		if not combatData[targetId] then return end

		local attackerHRP = Utility.GetHumanoidRootPart(player)
		local targetHRP   = Utility.GetHumanoidRootPart(targetPlayer)
		if not attackerHRP or not targetHRP then return end

		local dist = (attackerHRP.Position - targetHRP.Position).Magnitude
		if dist > CombatConfig.ATTACK_RANGE then
			print(string.format(
				"[CombatService] Атака отклонена: dist=%.1f > range=%d",
				dist, CombatConfig.ATTACK_RANGE
			))
			return
		end

		applyDamage(uid, targetPlayer, CombatConfig.ATTACK_DAMAGE)
	end
end

function CombatService.CheckWinCondition(allStates)
	local leftAlive  = 0
	local rightAlive = 0
	local hadLeft    = false
	local hadRight   = false

	for uid, data in pairs(combatData) do
		local state = allStates[uid]
		if not state then continue end

		local team = state.Team
		if team == Enums.Team.Left or team == "Left" then
			hadLeft = true
			if data.hp > 0 then leftAlive += 1 end
		elseif team == Enums.Team.Right or team == "Right" then
			hadRight = true
			if data.hp > 0 then rightAlive += 1 end
		end
	end

	if hadLeft and hadRight then
		if leftAlive == 0 and rightAlive > 0 then return Enums.Team.Right end
		if rightAlive == 0 and leftAlive > 0 then return Enums.Team.Left  end
		if leftAlive == 0 and rightAlive == 0 then return "Draw"           end
	elseif hadLeft and not hadRight then
		return Enums.Team.Left
	elseif hadRight and not hadLeft then
		return Enums.Team.Right
	end

	return nil
end

function CombatService.EndRound(playerList)
	for _, player in ipairs(playerList or {}) do
		removeWeapon(player)
	end

	for uid, conn in pairs(diedConns) do
		conn:Disconnect()
	end
	diedConns = {}

	if DonateService then
		DonateService.ClearActiveBombs(playerList)
	end

	print("[CombatService] EndRound: оружие изъято, соединения очищены.")
end

function CombatService.GetDiedInRound()
	return diedInRound
end

function CombatService.IsAlive(userId)
	return combatData[userId] ~= nil and combatData[userId].hp > 0
end

return CombatService