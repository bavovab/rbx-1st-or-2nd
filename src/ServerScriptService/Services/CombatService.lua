-- ModuleScript: ServerScriptService/Services/CombatService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Config       = ReplicatedStorage:WaitForChild("Config")
local Enums        = require(Shared:WaitForChild("Enums"))
local CombatConfig = require(Config:WaitForChild("CombatConfig"))
local Utility      = require(Shared:WaitForChild("Utility"))

local CombatService = {}

local playerStates
local teamService

local attackCooldowns = {}
local dashCooldowns   = {}
local blockCooldowns  = {}
local blockActive     = {}
local blockExpiry     = {}

local onEliminatedCallbacks = {}

function CombatService.Init(pss, ts)
	playerStates = pss
	teamService  = ts
end

function CombatService.OnPlayerEliminated(cb)
	table.insert(onEliminatedCallbacks, cb)
end

local function fireEliminated(victim, attacker)
	for _, cb in ipairs(onEliminatedCallbacks) do
		pcall(cb, victim, attacker)
	end
end

function CombatService.InitializeHP(players)
	attackCooldowns = {}
	dashCooldowns   = {}
	blockCooldowns  = {}
	blockActive     = {}
	blockExpiry     = {}

	local allStates = playerStates.GetAllStates()
	for _, player in ipairs(players) do
		local ps = allStates[player.UserId]
		if ps then
			ps.HP      = CombatConfig.MAX_HP
			ps.IsAlive = true
		end
	end
end

local function applyDamage(attacker, victim, damage)
	local allStates = playerStates.GetAllStates()
	local vs = allStates[victim.UserId]
	if not vs or not vs.IsAlive then return end

	local uid = victim.UserId
	if blockActive[uid] and os.clock() < (blockExpiry[uid] or 0) then
		damage = math.floor(damage * (1 - CombatConfig.BLOCK_REDUCTION))
	end

	vs.HP = math.max(0, vs.HP - damage)
	playerStates.AddDamage(attacker, damage)

	local hum = Utility.GetHumanoid(victim)
	if hum then
		hum.Health = math.max(0, hum.Health - damage)
	end

	if vs.HP <= 0 then
		vs.IsAlive = false
		blockActive[uid] = false
		playerStates.AddKill(attacker)
		if hum and hum.Health > 0 then hum.Health = 0 end
		fireEliminated(victim, attacker)
	end
end

local function findEnemyTarget(attacker, targetId)
	local allStates = playerStates.GetAllStates()
	local as = allStates[attacker.UserId]
	if not as then return nil end

	local targetPlayer = Players:GetPlayerByUserId(targetId)
	if not targetPlayer then return nil end

	local ts2 = allStates[targetPlayer.UserId]
	if not ts2 or not ts2.IsAlive then return nil end
	if ts2.Team == as.Team then return nil end
	if ts2.Team == Enums.Team.None then return nil end

	local ahrp = Utility.GetHumanoidRootPart(attacker)
	local thrp = Utility.GetHumanoidRootPart(targetPlayer)
	if not ahrp or not thrp then return nil end

	if (ahrp.Position - thrp.Position).Magnitude > CombatConfig.MAX_VALID_ATTACK_DIST then
		return nil
	end

	return targetPlayer
end

function CombatService.ProcessAction(player, payload)
	local action = payload.Action
	local now    = os.clock()
	local uid    = player.UserId
	local allStates = playerStates.GetAllStates()
	local ps = allStates[uid]
	if not ps or not ps.IsAlive then return end

	if action == Enums.CombatAction.Melee then
		if (attackCooldowns[uid] or 0) + CombatConfig.ATTACK_COOLDOWN > now then return end
		attackCooldowns[uid] = now
		local target = findEnemyTarget(player, payload.TargetId)
		if target then applyDamage(player, target, CombatConfig.ATTACK_DAMAGE) end

	elseif action == Enums.CombatAction.Dash then
		if (dashCooldowns[uid] or 0) + CombatConfig.DASH_COOLDOWN > now then return end
		dashCooldowns[uid] = now
		local hrp = Utility.GetHumanoidRootPart(player)
		if hrp then
			local newCF = hrp.CFrame + hrp.CFrame.LookVector * CombatConfig.DASH_DISTANCE
			local char  = player.Character
			if char then char:PivotTo(newCF) end
		end

	elseif action == Enums.CombatAction.Block then
		if (blockCooldowns[uid] or 0) + CombatConfig.BLOCK_COOLDOWN > now then return end
		blockCooldowns[uid] = now + CombatConfig.BLOCK_DURATION
		blockActive[uid]    = true
		blockExpiry[uid]    = now + CombatConfig.BLOCK_DURATION
		task.delay(CombatConfig.BLOCK_DURATION, function()
			blockActive[uid] = false
		end)
	end
end

-- ── Win condition ──
-- A team is "wiped" only if it had at least 1 player AND now has 0 alive.
-- An empty team (never had players) does NOT count as wiped.
function CombatService.CheckWinCondition(allPlayerStates)
	local leftTotal,  leftAlive  = 0, 0
	local rightTotal, rightAlive = 0, 0

	for _, ps in pairs(allPlayerStates) do
		if not ps.InRound then continue end
		if ps.Team == Enums.Team.Left then
			leftTotal = leftTotal + 1
			if ps.IsAlive then leftAlive = leftAlive + 1 end
		elseif ps.Team == Enums.Team.Right then
			rightTotal = rightTotal + 1
			if ps.IsAlive then rightAlive = rightAlive + 1 end
		end
	end

	-- Need at least one team with players to evaluate
	if leftTotal == 0 and rightTotal == 0 then return nil end

	local leftWiped  = leftTotal  > 0 and leftAlive  == 0
	local rightWiped = rightTotal > 0 and rightAlive == 0

	if leftWiped and rightWiped then return "Draw" end
	if leftWiped  then return "Right" end
	if rightWiped then return "Left"  end

	return nil -- battle continues
end

function CombatService.GetCooldownInfo(player)
	local now = os.clock()
	local uid = player.UserId
	return {
		AttackReady = (attackCooldowns[uid] or 0) + CombatConfig.ATTACK_COOLDOWN <= now,
		DashReady   = (dashCooldowns[uid]   or 0) + CombatConfig.DASH_COOLDOWN   <= now,
		BlockReady  = (blockCooldowns[uid]  or 0) + CombatConfig.BLOCK_COOLDOWN  <= now,
	}
end

return CombatService