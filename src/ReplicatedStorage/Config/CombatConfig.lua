-- CombatConfig.lua

local CombatConfig = {}

CombatConfig.MAX_HP           = 100
CombatConfig.ATTACK_DAMAGE    = 25
CombatConfig.ATTACK_RANGE     = 8       -- studs
CombatConfig.ATTACK_COOLDOWN  = 0.6    -- seconds
CombatConfig.DASH_DISTANCE    = 20      -- studs
CombatConfig.DASH_COOLDOWN    = 3.0    -- seconds
CombatConfig.BLOCK_REDUCTION  = 0.5    -- 50% damage blocked
CombatConfig.BLOCK_DURATION   = 2.0   -- max seconds block is active per use
CombatConfig.BLOCK_COOLDOWN   = 4.0   -- seconds before block can be used again

-- Server-side sanity: max allowed time between client request and server processing
CombatConfig.MAX_REQUEST_LAG  = 1.0   -- seconds

return CombatConfig