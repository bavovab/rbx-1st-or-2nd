-- ChoiceLibrary.lua
-- Choice pair definitions and weighted random selection with history avoidance.

local Utility = require(script.Parent.Utility)

local ChoiceLibrary = {}

local PAIRS = {
	{
		Id           = "NinjasVsPirates",
		LeftText     = "Ninjas",
		RightText    = "Pirates",
		LeftColor    = Color3.fromRGB(30, 30, 30),
		RightColor   = Color3.fromRGB(200, 40, 40),
		Category     = "Adventure",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 10,
	},
	{
		Id           = "MagicVsMecha",
		LeftText     = "Magic",
		RightText    = "Mecha",
		LeftColor    = Color3.fromRGB(140, 60, 220),
		RightColor   = Color3.fromRGB(120, 120, 130),
		Category     = "Fantasy",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 10,
	},
	{
		Id           = "IceVsFire",
		LeftText     = "Ice",
		RightText    = "Fire",
		LeftColor    = Color3.fromRGB(80, 160, 240),
		RightColor   = Color3.fromRGB(240, 100, 20),
		Category     = "Elemental",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 12,
	},
	{
		Id           = "SpeedVsStrength",
		LeftText     = "Speed",
		RightText    = "Strength",
		LeftColor    = Color3.fromRGB(240, 220, 20),
		RightColor   = Color3.fromRGB(180, 90, 20),
		Category     = "Power",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 9,
	},
	{
		Id           = "SamuraiVsHunters",
		LeftText     = "Samurai",
		RightText    = "Hunters",
		LeftColor    = Color3.fromRGB(200, 30, 30),
		RightColor   = Color3.fromRGB(80, 110, 50),
		Category     = "Warriors",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 10,
	},
	{
		Id           = "LightVsShadow",
		LeftText     = "Light",
		RightText    = "Shadow",
		LeftColor    = Color3.fromRGB(255, 250, 220),
		RightColor   = Color3.fromRGB(20, 20, 30),
		Category     = "Elemental",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 11,
	},
	{
		Id           = "StormVsEarth",
		LeftText     = "Storm",
		RightText    = "Earth",
		LeftColor    = Color3.fromRGB(60, 180, 220),
		RightColor   = Color3.fromRGB(120, 80, 40),
		Category     = "Elemental",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 8,
	},
	{
		Id           = "WolvesVsEagles",
		LeftText     = "Wolves",
		RightText    = "Eagles",
		LeftColor    = Color3.fromRGB(80, 100, 140),
		RightColor   = Color3.fromRGB(200, 170, 30),
		Category     = "Animals",
		RevealSfxKey = "RevealGeneric",
		Allowed      = true,
		Weight       = 8,
	},
}

local function GetEligiblePairs(recentHistory)
	local eligible = {}
	for _, entry in ipairs(PAIRS) do
		if entry.Allowed and not Utility.TableContains(recentHistory, entry.Id) then
			table.insert(eligible, entry)
		end
	end
	if #eligible == 0 then
		for _, entry in ipairs(PAIRS) do
			if entry.Allowed then
				table.insert(eligible, entry)
			end
		end
	end
	return eligible
end

function ChoiceLibrary.GetRandomPair(recentHistory)
	local eligible = GetEligiblePairs(recentHistory or {})
	local totalWeight = 0
	local cumulative = {}
	for _, entry in ipairs(eligible) do
		totalWeight = totalWeight + entry.Weight
		table.insert(cumulative, { weight = totalWeight, entry = entry })
	end
	if totalWeight == 0 then
		return eligible[1]
	end
	local roll = math.random(1, totalWeight)
	for _, c in ipairs(cumulative) do
		if roll <= c.weight then
			return c.entry
		end
	end
	return eligible[#eligible]
end

function ChoiceLibrary.GetPairById(id)
	for _, entry in ipairs(PAIRS) do
		if entry.Id == id then return entry end
	end
	return nil
end

function ChoiceLibrary.GetAllAllowed()
	local result = {}
	for _, entry in ipairs(PAIRS) do
		if entry.Allowed then
			table.insert(result, entry)
		end
	end
	return result
end

return ChoiceLibrary