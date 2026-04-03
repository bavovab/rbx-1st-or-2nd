-- ModuleScript (без изменений по логике, оставлен полным для удобства)
local Enums = {}

Enums.Phase = {
	Intermission       = "Intermission",
	TeleportToPreArena = "TeleportToPreArena",
	RevealChoiceA      = "RevealChoiceA",
	RevealChoiceB      = "RevealChoiceB",
	DarkChoice         = "DarkChoice",
	LockChoice         = "LockChoice",
	AssignTeams        = "AssignTeams",
	TeleportToBattle   = "TeleportToBattle",
	Battle             = "Battle",
	Victory            = "Victory",
	Celebration        = "Celebration",
	ReturnToLobby      = "ReturnToLobby",
	Cleanup            = "Cleanup",
}

Enums.Team = {
	Left  = "Left",
	Right = "Right",
	None  = "None",
}

Enums.CombatAction = {
	Melee = "Melee",
	Dash  = "Dash",
	Block = "Block",
}

Enums.UndecidedMode = {
	RandomAssign = "RandomAssign",
	SpectateOnly = "SpectateOnly",
}

return Enums