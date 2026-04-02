-- UIConfig.lua

local UIConfig = {}

UIConfig.LEFT_COLOR_DEFAULT  = Color3.fromRGB(60, 120, 220)
UIConfig.RIGHT_COLOR_DEFAULT = Color3.fromRGB(220, 60, 60)
UIConfig.NEUTRAL_COLOR       = Color3.fromRGB(50, 50, 60)
UIConfig.WIN_COLOR           = Color3.fromRGB(40, 200, 80)
UIConfig.LOSE_COLOR          = Color3.fromRGB(200, 50, 50)
UIConfig.DRAW_COLOR          = Color3.fromRGB(200, 180, 40)
UIConfig.TEXT_PRIMARY        = Color3.fromRGB(255, 255, 255)
UIConfig.TEXT_SECONDARY      = Color3.fromRGB(200, 200, 200)
UIConfig.BACKGROUND_DARK     = Color3.fromRGB(15, 15, 20)
UIConfig.BACKGROUND_PANEL    = Color3.fromRGB(25, 25, 35)

UIConfig.TWEEN_FAST          = 0.15  -- seconds
UIConfig.TWEEN_MEDIUM        = 0.3
UIConfig.TWEEN_SLOW          = 0.6

UIConfig.BANNER_FONT         = Enum.Font.GothamBold
UIConfig.BODY_FONT           = Enum.Font.Gotham

UIConfig.CHOICE_CARD_SIZE    = UDim2.new(0.38, 0, 0.55, 0)
UIConfig.HUD_BAR_HEIGHT      = 40
UIConfig.TIMER_SIZE          = UDim2.new(0, 120, 0, 40)

UIConfig.LABELS = {
	Intermission       = "Waiting for players...",
	TeleportToPreArena = "Heading to the arena!",
	RevealChoiceA      = "The choice is revealed...",
	RevealChoiceB      = "...and the other side!",
	DarkChoice         = "Choose your side!",
	LockChoice         = "Choices locked!",
	AssignTeams        = "Assigning teams...",
	TeleportToBattle   = "Battle begins!",
	Battle             = "FIGHT!",
	Victory            = "Round over!",
	Celebration        = "Victory!",
	ReturnToLobby      = "Returning to lobby...",
	Cleanup            = "",
}

UIConfig.TEST_MODE_LABEL     = "[TEST MODE]"

return UIConfig