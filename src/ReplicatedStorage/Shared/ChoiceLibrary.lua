-- ModuleScript: ReplicatedStorage/Shared/ChoiceLibrary
-- Каждый раунд выбирает 2 случайных РАЗНЫХ варианта из CHOICES.
-- Избегает повторения пар из недавней истории.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentConfig = require(
	ReplicatedStorage:WaitForChild("Config"):WaitForChild("ContentConfig")
)

local ChoiceLibrary = {}

-- История последних пар (список из {IdA, IdB})
local recentPairs = {}

-- Строим пул разрешённых вариантов
local function buildPool()
	local pool = {}
	for _, entry in ipairs(ContentConfig.CHOICES) do
		if entry.Allowed then
			table.insert(pool, entry)
		end
	end
	if #pool < 2 then
		warn("[ChoiceLibrary] Нужно минимум 2 варианта с Allowed=true!")
	end
	return pool
end

-- Взвешенный случайный выбор из списка, исключая один ID
local function weightedPick(pool, excludeId)
	local filtered = {}
	for _, item in ipairs(pool) do
		if item.Id ~= excludeId then
			table.insert(filtered, item)
		end
	end
	if #filtered == 0 then return nil end

	local total = 0
	for _, item in ipairs(filtered) do
		total = total + (item.Weight or 1)
	end

	local roll       = math.random() * total
	local cumulative = 0
	local chosen     = filtered[#filtered]
	for _, item in ipairs(filtered) do
		cumulative = cumulative + (item.Weight or 1)
		if roll <= cumulative then
			chosen = item
			break
		end
	end
	return chosen
end

-- Проверяем была ли пара недавно (в любом порядке)
local function wasRecentPair(idA, idB)
	for _, p in ipairs(recentPairs) do
		if (p[1] == idA and p[2] == idB) or
		   (p[1] == idB and p[2] == idA) then
			return true
		end
	end
	return false
end

-- Возвращает { Left = entry, Right = entry }
function ChoiceLibrary.GetRandomPair(maxHistory)
	maxHistory = maxHistory or 3
	local pool = buildPool()

	-- Fallback если вариантов меньше 2
	if #pool < 2 then
		local fallbackA = {
			Id = "Left", Text = "LEFT",
			Color = Color3.fromRGB(0, 90, 200), Image = 0,
		}
		local fallbackB = {
			Id = "Right", Text = "RIGHT",
			Color = Color3.fromRGB(200, 60, 0), Image = 0,
		}
		return { Left = fallbackA, Right = fallbackB }
	end

	-- Пробуем до 20 раз найти не-повторяющуюся пару
	local chosenA, chosenB
	local attempts = 0

	repeat
		attempts = attempts + 1
		chosenA = weightedPick(pool, nil)
		chosenB = weightedPick(pool, chosenA.Id)
	until not wasRecentPair(chosenA.Id, chosenB.Id) or attempts >= 20

	-- Запоминаем пару в историю
	table.insert(recentPairs, { chosenA.Id, chosenB.Id })
	if #recentPairs > maxHistory then
		table.remove(recentPairs, 1)
	end

	return { Left = chosenA, Right = chosenB }
end

function ChoiceLibrary.GetById(id)
	for _, entry in ipairs(ContentConfig.CHOICES) do
		if entry.Id == id then return entry end
	end
	return nil
end

function ChoiceLibrary.ResetHistory()
	recentPairs = {}
end

return ChoiceLibrary