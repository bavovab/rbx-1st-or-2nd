-- ModuleScript
-- Выбирает две случайные независимые опции из ContentConfig.OPTIONS.
-- Гарантирует что обе опции разные и не повторяют недавние пары.

local ContentConfig = require(script.Parent.Parent.Config.ContentConfig)

local ChoiceLibrary = {}

-- История: хранит Id опций использованных недавно (обе стороны)
local recentIds = {}

local function weightedPick(pool)
	local total = 0
	for _, item in ipairs(pool) do
		total = total + (item.Weight or 1)
	end
	local roll = math.random() * total
	local cumulative = 0
	for _, item in ipairs(pool) do
		cumulative = cumulative + (item.Weight or 1)
		if roll <= cumulative then
			return item
		end
	end
	return pool[#pool]
end

local function wasRecent(id)
	for _, rid in ipairs(recentIds) do
		if rid == id then return true end
	end
	return false
end

-- Возвращает таблицу { Left = option, Right = option }
-- Обе опции случайные и независимые друг от друга
function ChoiceLibrary.GetRandomPair(maxHistory)
	maxHistory = maxHistory or 4

	local allOptions = ContentConfig.OPTIONS

	-- Сначала фильтруем недавно использованные
	local freshPool = {}
	for _, opt in ipairs(allOptions) do
		if not wasRecent(opt.Id) then
			table.insert(freshPool, opt)
		end
	end

	-- Если свежих меньше 2 — сбрасываем историю и берём все
	if #freshPool < 2 then
		recentIds = {}
		freshPool = {}
		for _, opt in ipairs(allOptions) do
			table.insert(freshPool, opt)
		end
	end

	-- Выбираем Left
	local leftOpt = weightedPick(freshPool)

	-- Убираем leftOpt из пула для выбора Right
	local rightPool = {}
	for _, opt in ipairs(freshPool) do
		if opt.Id ~= leftOpt.Id then
			table.insert(rightPool, opt)
		end
	end

	local rightOpt = weightedPick(rightPool)

	-- Обновляем историю
	table.insert(recentIds, leftOpt.Id)
	table.insert(recentIds, rightOpt.Id)
	while #recentIds > maxHistory * 2 do
		table.remove(recentIds, 1)
	end

	return {
		Left  = leftOpt,
		Right = rightOpt,
		-- удобные поля для обратной совместимости с RoundService
		LeftText     = leftOpt.Text,
		RightText    = rightOpt.Text,
		LeftColor    = leftOpt.Color,
		RightColor   = rightOpt.Color,
		LeftImageId  = leftOpt.ImageId  or 0,
		RightImageId = rightOpt.ImageId or 0,
		RevealSfxKey = "RevealSting1",
	}
end

function ChoiceLibrary.ResetHistory()
	recentIds = {}
end

return ChoiceLibrary