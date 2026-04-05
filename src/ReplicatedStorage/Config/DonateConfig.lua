-- ModuleScript
local DonateConfig = {}

-- ID Developer Product из Creator Hub (не Asset ID, а именно Product ID)
-- Создай продукт: Creator Hub → Monetization → Developer Products → Create
DonateConfig.BOMB_PRODUCT_ID = 0       -- ← вставь свой Product ID

DonateConfig.BOMB_TOOL_NAME  = "TeamBomb"   -- имя Tool в Workspace
DonateConfig.BOMB_USES       = 1            -- сколько раз можно использовать за раунд

return DonateConfig