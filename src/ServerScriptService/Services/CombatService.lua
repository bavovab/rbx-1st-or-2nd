local Players        = game:GetService("Players")
local Enums          = require(game.ReplicatedStorage.Shared.Enums)
local CombatConfig   = require(game.ReplicatedStorage.Config.CombatConfig)
local Utility        = require(game.ReplicatedStorage.Shared.Utility)
local PlayerStateSvc = require(script.Parent.PlayerStateService)
local TeamService    = require(script.Parent.TeamService)

local RemotesFolder      = game.ReplicatedStorage:WaitForChild("Remotes")
local RemotePlayerElim   = RemotesFolder:WaitForChild("PlayerEliminated")
local RemoteHPUpdate     = RemotesFolder:WaitForChild("HPUpdate")

local CombatService = {}

local _hp         = {}
local _blockState = {}
local _onEliminated = nil
local _onWinner     = nil

function CombatService.SetEliminatedCallback(fn)
	_onEliminated = fn
end

function CombatService.SetWinnerCallback(fn)
	_onWinner = fn
end

function CombatService.InitializePlayers(players)
	_hp         = {}
	_blockState = {}
	for _, player in ipairs(players) do
		_hp[player]         = CombatConfig.MAX_HP
		_blockState[player] = { active = false, startTime = 0 }
		local hum = Utility.GetHumanoid(player)
		if hum then
			hum.MaxHealth          = CombatConfig.MAX_HP
			hum.Health             = CombatConfig.MAX_HP
			hum.AutoRotate         = true
			hum.BreakJointsOnDeath = false
		end
	end
end

function CombatService.GetHP(player)
	return _hp[player] or 0
end

function CombatService.GetTotalHP(side)
	local total = 0
	local teamPlayers = TeamService.GetTeam(side)
	for _, p in ipairs(teamPlayers) do
		local state = PlayerStateSvc.Get(p)
		if state and state.IsAlive then
			total = total + (_hp[p] or 0)
		end
	end
	return total
end

local function EliminatePlayer(player, killer)
	if not PlayerStateSvc.Get(player) then return end
	if not PlayerStateSvc.Get(player).IsAlive then return end
	PlayerStateSvc.SetAlive(player, false)
	_hp[player] = 0
	local hum = Utility.GetHumanoid(player)
	if hum then
		hum.Health = 0
	end
	RemotePlayerElim:FireAllClients(player.Name)
	if killer and PlayerStateSvc.Get(killer) then
		PlayerStateSvc.AddKill(killer)
	end
	if _onEliminated then
		_onEliminated(player, killer)
	end
end

local function ApplyDamage(attacker, target, rawDamage)
	if not _hp[target] then return end
	local damage = rawDamage
	local bs = _blockState[target]
	if bs and bs.active then
		if (os.clock() - bs.startTime) > CombatConfig.BLOCK_DURATION then
			bs.active = false
		else
			damage = damage * (1 - CombatConfig.BLOCK_REDUCTION)
		end
	end
	damage = math.floor(damage)
	_hp[target] = math.max(0, _hp[target] - damage)
	PlayerStateSvc.AddDamage(attacker, damage)
	local hum = Utility.GetHumanoid(target)
	if hum and hum.Health > 0 then
		hum.Health = _hp[target]
	end
	RemoteHPUpdate:FireClient(target, _hp[target], CombatConfig.MAX_HP)
	if _hp[target] <= 0 then
		EliminatePlayer(target, attacker)
	end
end

local function FindEnemyTarget(attacker, enemySide)
	local root = Utility.GetHumanoidRootPart(attacker)
	if not root then return nil end
	local attackerPos = root.Position
	local bestDist    = math.huge
	local bestTarget  = nil
	local enemies     = TeamService.GetTeam(enemySide)
	for _, enemy in ipairs(enemies) do
		local state = PlayerStateSvc.Get(enemy)
		if state and state.IsAlive then
			local eroot = Utility.GetHumanoidRootPart(enemy)
			if eroot then
				local dist = (eroot.Position - attackerPos).Magnitude
				if dist <= CombatConfig.ATTACK_RANGE and dist < bestDist then
					bestDist   = dist
					bestTarget = enemy
				end
			end
		end
	end
	return bestTarget
end

local function FindEnemyById(attacker, enemySide, targetUserId)
	local root = Utility.GetHumanoidRootPart(attacker)
	if not root then return nil end
	local attackerPos = root.Position
	local enemies     = TeamService.GetTeam(enemySide)
	for _, enemy in ipairs(enemies) do
		if enemy.UserId == targetUserId then
			local state = PlayerStateSvc.Get(enemy)
			if state and state.IsAlive then
				local eroot = Utility.GetHumanoidRootPart(enemy)
				if eroot then
					local dist = (eroot.Position - attackerPos).Magnitude
					if dist <= CombatConfig.ATTACK_RANGE then
						return enemy
					end
				end
			end
			break
		end
	end
	return nil
end

function CombatService.ProcessInput(attacker, action, targetUserId)
	local state = PlayerStateSvc.Get(attacker)
	if not state or not state.IsAlive then return end

	local attackerTeam = TeamService.GetTeamOf(attacker)
	if attackerTeam == Enums.Team.None then return end
	local enemySide = (attackerTeam == Enums.Team.Left) and Enums.Team.Right or Enums.Team.Left

	if action == Enums.CombatAction.Attack then
		local target
		if targetUserId then
			target = FindEnemyById(attacker, enemySide, targetUserId)
		else
			target = FindEnemyTarget(attacker, enemySide)
		end
		if target then
			ApplyDamage(attacker, target, CombatConfig.ATTACK_DAMAGE)
		end

	elseif action == Enums.CombatAction.Dash then
		local root = Utility.GetHumanoidRootPart(attacker)
		if root then
			local lookDir = root.CFrame.LookVector
			root.CFrame   = root.CFrame + lookDir * CombatConfig.DASH_DISTANCE
		end

	elseif action == Enums.CombatAction.Block then
		local bs = _blockState[attacker]
		if bs then
			bs.active    = true
			bs.startTime = os.clock()
		end
	end

	CombatService.CheckWinCondition()
end

function CombatService.CheckWinCondition()
	local leftAlive  = TeamService.GetAliveCount(Enums.Team.Left)
	local rightAlive = TeamService.GetAliveCount(Enums.Team.Right)

	if leftAlive == 0 and rightAlive == 0 then
		if _onWinner then _onWinner(nil, Enums.WinnerReason.Draw) end
		return true
	elseif leftAlive == 0 then
		if _onWinner then _onWinner(Enums.Team.Right, Enums.WinnerReason.Wipeout) end
		return true
	elseif rightAlive == 0 then
		if _onWinner then _onWinner(Enums.Team.Left, Enums.WinnerReason.Wipeout) end
		return true
	end
	return false
end

function CombatService.ResolveByTimer()
	local leftAlive  = TeamService.GetAliveCount(Enums.Team.Left)
	local rightAlive = TeamService.GetAliveCount(Enums.Team.Right)
	if leftAlive > rightAlive then
		return Enums.Team.Left, Enums.WinnerReason.AliveCount
	elseif rightAlive > leftAlive then
		return Enums.Team.Right, Enums.WinnerReason.AliveCount
	end
	local leftHP  = CombatService.GetTotalHP(Enums.Team.Left)
	local rightHP = CombatService.GetTotalHP(Enums.Team.Right)
	if leftHP > rightHP then
		return Enums.Team.Left, Enums.WinnerReason.TotalHP
	elseif rightHP > leftHP then
		return Enums.Team.Right, Enums.WinnerReason.TotalHP
	end
	return nil, Enums.WinnerReason.Draw
end

function CombatService.Cleanup()
	_hp         = {}
	_blockState = {}
end

return CombatService