-- GameConfig.lua

local GameConfig = {}

GameConfig.MIN_PLAYERS         = 1
GameConfig.TEST_MODE           = true
GameConfig.INTERMISSION_TIME   = 15
GameConfig.CHOICE_TIME         = 12
GameConfig.BATTLE_TIME         = 60
GameConfig.CELEBRATION_TIME    = 5
GameConfig.RETURN_DELAY        = 2
GameConfig.AUTO_ASSIGN_UNDECIDED = true
GameConfig.UNDECIDED_MODE      = "Random"   -- "Random" | "Smaller" | "Eliminate"
GameConfig.MAX_HISTORY_PAIRS   = 3

return GameConfig