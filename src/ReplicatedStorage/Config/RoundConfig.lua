-- RoundConfig.lua

local GameConfig = require(script.Parent.GameConfig)

local RoundConfig = {}

RoundConfig.PHASES = {
	"Intermission",
	"TeleportToPreArena",
	"RevealChoiceA",
	"RevealChoiceB",
	"DarkChoice",
	"LockChoice",
	"AssignTeams",
	"TeleportToBattle",
	"Battle",
	"Victory",
	"Celebration",
	"ReturnToLobby",
	"Cleanup",
}

RoundConfig.PHASE_DURATIONS = {
	Intermission       = GameConfig.INTERMISSION_TIME,
	TeleportToPreArena = 3,
	RevealChoiceA      = 4,
	RevealChoiceB      = 4,
	DarkChoice         = GameConfig.CHOICE_TIME,
	LockChoice         = 1,
	AssignTeams        = 1,
	TeleportToBattle   = 3,
	Battle             = GameConfig.BATTLE_TIME,
	Victory            = 2,
	Celebration        = GameConfig.CELEBRATION_TIME,
	ReturnToLobby      = GameConfig.RETURN_DELAY,
	Cleanup            = 1,
}

RoundConfig.TIMER_WIN_PRIORITY = { "AliveCount", "TotalHP", "Draw" }
RoundConfig.DRAW_BOTH_WIN      = true

return RoundConfig