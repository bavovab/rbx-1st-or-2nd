-- ModuleScript
local GameConfig = {}

GameConfig.MIN_PLAYERS          = 1
GameConfig.TEST_MODE            = true

GameConfig.INTERMISSION_TIME    = 15
GameConfig.PRE_ARENA_WAIT_TIME  = 3
GameConfig.REVEAL_A_TIME        = 3
GameConfig.REVEAL_B_TIME        = 3
GameConfig.DARK_CHOICE_TIME     = 10
GameConfig.BATTLE_TIME          = 60
GameConfig.CELEBRATION_TIME     = 5
GameConfig.RETURN_DELAY         = 2

GameConfig.AUTO_ASSIGN_UNDECIDED = true
GameConfig.UNDECIDED_MODE        = "RandomAssign"

GameConfig.MAX_HISTORY_PAIRS     = 3

GameConfig.LOBBY_FALLBACK_CFRAME = CFrame.new(0, 5, 0)

return GameConfig