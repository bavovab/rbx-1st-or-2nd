-- Utility.lua
-- Common helpers shared between server and client.

local Utility = {}

function Utility.GetCharacter(player)
	if not player then return nil end
	return player.Character or nil
end

function Utility.GetHumanoid(player)
	local char = Utility.GetCharacter(player)
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

function Utility.GetHumanoidRootPart(player)
	local char = Utility.GetCharacter(player)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

function Utility.IsAlive(player)
	local hum = Utility.GetHumanoid(player)
	return hum ~= nil and hum.Health > 0
end

function Utility.FindPath(root, pathTable)
	local current = root
	for _, name in ipairs(pathTable) do
		if current == nil then return nil end
		current = current:FindFirstChild(name)
	end
	return current
end

function Utility.ShuffleArray(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function Utility.ShallowCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

function Utility.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

function Utility.TableContains(t, value)
	for _, v in ipairs(t) do
		if v == value then return true end
	end
	return false
end

function Utility.RemoveValue(t, value)
	for i, v in ipairs(t) do
		if v == value then
			table.remove(t, i)
			return true
		end
	end
	return false
end

function Utility.DictCount(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

function Utility.DictKeys(t)
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	return keys
end

function Utility.Clamp(value, min, max)
	if value < min then return min end
	if value > max then return max end
	return value
end

function Utility.Lerp(a, b, t)
	return a + (b - a) * t
end

return Utility