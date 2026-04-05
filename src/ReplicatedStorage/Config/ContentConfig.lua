-- ModuleScript
local ContentConfig = {}

-- ══════════════════════════════════════════════════════════
-- ОТДЕЛЬНЫЕ ВАРИАНТЫ (ChoiceLibrary сам собирает пары из них)
-- Для каждого варианта задай:
--   Text    — название
--   Color   — цвет карточки
--   Image   — rbxassetid картинки (0 = заглушка)
--   Music   — rbxassetid трека    (0 = тишина)
--   Weight  — вес при случайном выборе (1 = обычный)
--   Allowed — участвует ли в пуле
-- ══════════════════════════════════════════════════════════
ContentConfig.CHOICES = {
	{
		Id      = "Ninja",
		Text    = "NINJA",
		Color   = Color3.fromRGB(30, 30, 30),
		Image   = 126403603812646,     -- ← вставь asset ID картинки
		Music   = 79219995201078,     -- ← вставь asset ID музыки
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Pirate",
		Text    = "PIRATE",
		Color   = Color3.fromRGB(139, 69, 19),
		Image   = 126403603812646,
		Music   = 79219995201078,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Ice",
		Text    = "ICE",
		Color   = Color3.fromRGB(100, 180, 255),
		Image   = 126403603812646,
		Music   = 79219995201078,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Fire",
		Text    = "FIRE",
		Color   = Color3.fromRGB(255, 80, 20),
		Image   = 126403603812646,
		Music   = 79219995201078,
		Weight  = 1,
		Allowed = true,
	},
	{
		Id      = "Power",
		Text    = "POWER",
		Color   = Color3.fromRGB(180, 50, 220),
		Image   = 126403603812646,
		Music   = 79219995201078,
		Weight  = 1,
		Allowed = true,
	},
}

-- Анимации победы
ContentConfig.ANIMATION_IDS = {
	Celebrate1 = 0,
	Celebrate2 = 0,
}

-- Звуки
ContentConfig.SOUND_IDS = {
	Victory = 0,
}

-- Музыка фаз (не зависит от варианта)
ContentConfig.PHASE_MUSIC = {
	DarkChoice  = 0,   -- во время голосования
	Battle      = 0,   -- во время битвы
	Celebration = 0,   -- во время праздника
}

return ContentConfig