-- ModuleScript
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
	TeleportToPreArena = GameConfig.PRE_ARENA_WAIT_TIME,
	RevealChoiceA      = GameConfig.REVEAL_A_TIME,
	RevealChoiceB      = GameConfig.REVEAL_B_TIME,
	DarkChoice         = GameConfig.DARK_CHOICE_TIME,
	LockChoice         = 1,
	AssignTeams        = 1,
	TeleportToBattle   = 1.5,
	Battle             = GameConfig.BATTLE_TIME,
	Victory            = 1.5,
	Celebration        = GameConfig.CELEBRATION_TIME,
	ReturnToLobby      = GameConfig.RETURN_DELAY,
	Cleanup            = 0.5,
}

-- Используется в TeamService.ResolveWinner когда таймер истёк
-- Порядок приоритетов: сначала кол-во живых, потом суммарный HP, потом ничья
RoundConfig.WINNER_RESOLVE_ORDER = { "AliveCount", "TotalHP", "Draw" }

RoundConfig.DRAW_BOTH_WIN = true

return RoundConfig