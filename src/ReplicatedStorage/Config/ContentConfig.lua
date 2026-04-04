-- ModuleScript: ReplicatedStorage/Config/ContentConfig

local ContentConfig = {}

-- Каждый вариант — самостоятельная единица.
-- Сервер каждый раунд берёт 2 случайных РАЗНЫХ варианта.
-- Image = Asset ID твоей картинки (загрузи в Creator Dashboard → Decals)
ContentConfig.CHOICES = {
	{
		Id      = "Ninja",
		Text    = "NINJA",
		Color   = Color3.fromRGB(30,  30,  30),
		Image   = 126403603812646,      -- ← вставь Asset ID
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Pirate",
		Text    = "PIRATE",
		Color   = Color3.fromRGB(180, 80,   0),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Magic",
		Text    = "MAGIC",
		Color   = Color3.fromRGB(120,  0, 200),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Mecha",
		Text    = "MECHA",
		Color   = Color3.fromRGB(0,  120, 200),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Ice",
		Text    = "ICE",
		Color   = Color3.fromRGB(0,  180, 220),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Fire",
		Text    = "FIRE",
		Color   = Color3.fromRGB(220, 60,   0),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Speed",
		Text    = "SPEED",
		Color   = Color3.fromRGB(220, 200,  0),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Power",
		Text    = "POWER",
		Color   = Color3.fromRGB(180, 40,  40),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Samurai",
		Text    = "SAMURAI",
		Color   = Color3.fromRGB(160,  0,  40),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Hunter",
		Text    = "HUNTER",
		Color   = Color3.fromRGB(40,  100, 40),
		Image   = 126403603812646,
		Weight  = 1,
		Allowed = true,
	},
	-- Добавляй сколько угодно новых вариантов сюда:
	-- {
	--     Id      = "Dragon",
	--     Text    = "DRAGON",
	--     Color   = Color3.fromRGB(200, 0, 0),
	--     Image   = 0,
	--     Weight  = 1,
	--     Allowed = true,
	-- },
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

assert(
	type(ContentConfig.CHOICES) == "table" and #ContentConfig.CHOICES >= 2,
	"[ContentConfig] CHOICES должен содержать минимум 2 варианта!"
)

return ContentConfig