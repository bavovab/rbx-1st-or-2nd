-- ModuleScript
-- Каждый элемент - отдельная опция, не пара.
-- Система сама случайно выберет две разные опции за раунд.

local ContentConfig = {}

ContentConfig.OPTIONS = {
	{
		Id       = "Ninjas",
		Text     = "🥷 Ninjas",
		Color    = Color3.fromRGB(30, 30, 30),
		ImageId  = 0,  -- вставь свой AssetId
		Category = "Warriors",
		Weight   = 1,
	},
	{
		Id       = "Pirates",
		Text     = "🏴‍☠️ Pirates",
		Color    = Color3.fromRGB(180, 80, 0),
		ImageId  = 0,
		Category = "Warriors",
		Weight   = 1,
	},
	{
		Id       = "Magic",
		Text     = "✨ Magic",
		Color    = Color3.fromRGB(120, 0, 200),
		ImageId  = 0,
		Category = "Power",
		Weight   = 1,
	},
	{
		Id       = "Mecha",
		Text     = "⚙️ Mecha",
		Color    = Color3.fromRGB(0, 120, 200),
		ImageId  = 0,
		Category = "Power",
		Weight   = 1,
	},
	{
		Id       = "Ice",
		Text     = "❄️ Ice",
		Color    = Color3.fromRGB(0, 180, 220),
		ImageId  = 0,
		Category = "Elements",
		Weight   = 1,
	},
	{
		Id       = "Fire",
		Text     = "🔥 Fire",
		Color    = Color3.fromRGB(220, 60, 0),
		ImageId  = 0,
		Category = "Elements",
		Weight   = 1,
	},
	{
		Id       = "Speed",
		Text     = "⚡ Speed",
		Color    = Color3.fromRGB(220, 200, 0),
		ImageId  = 0,
		Category = "Attributes",
		Weight   = 1,
	},
	{
		Id       = "Strength",
		Text     = "💪 Strength",
		Color    = Color3.fromRGB(180, 40, 40),
		ImageId  = 0,
		Category = "Attributes",
		Weight   = 1,
	},
	{
		Id       = "Samurai",
		Text     = "⚔️ Samurai",
		Color    = Color3.fromRGB(160, 0, 40),
		ImageId  = 0,
		Category = "Warriors",
		Weight   = 1,
	},
	{
		Id       = "Hunters",
		Text     = "🏹 Hunters",
		Color    = Color3.fromRGB(40, 100, 40),
		ImageId  = 0,
		Category = "Warriors",
		Weight   = 1,
	},
	{
		Id       = "Dragons",
		Text     = "🐉 Dragons",
		Color    = Color3.fromRGB(160, 30, 200),
		ImageId  = 0,
		Category = "Creatures",
		Weight   = 1,
	},
	{
		Id       = "Robots",
		Text     = "🤖 Robots",
		Color    = Color3.fromRGB(60, 160, 180),
		ImageId  = 0,
		Category = "Power",
		Weight   = 1,
	},
}

ContentConfig.ANIMATION_IDS = {
	Celebrate1 = 0,
	Celebrate2 = 0,
}

ContentConfig.SOUND_IDS = {
	RevealSting1  = 0,
	RevealSting2  = 0,
	WinSting      = 0,
	CountdownTick = 0,
}

return ContentConfig