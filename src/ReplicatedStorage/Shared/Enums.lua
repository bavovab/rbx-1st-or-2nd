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
	Attack = "Attack",
	Dash   = "Dash",
	Block  = "Block",
}

Enums.WinnerReason = {
	Wipeout    = "Wipeout",
	AliveCount = "AliveCount",
	TotalHP    = "TotalHP",
	Draw       = "Draw",
	TimerEnd   = "TimerEnd",
}

Enums.UndecidedMode = {
	Random    = "Random",
	Smaller   = "Smaller",
	Eliminate = "Eliminate",
}

return Enums