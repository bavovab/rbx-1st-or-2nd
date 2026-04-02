-- ContentConfig.lua
-- Safe placeholder asset IDs. Replace with real uploaded asset IDs.
-- All audio must be uploaded to Roblox by the game owner to comply with content policy.

local ContentConfig = {}

-- SFX asset ID placeholders (replace with your own uploaded audio asset IDs)
ContentConfig.SFX = {
	RevealGeneric  = 0,   -- played when a choice side is revealed
	DarknessStart  = 0,   -- played when arena goes dark
	ChoiceLock     = 0,   -- played when choices are locked
	BattleStart    = 0,   -- played at battle start
	VictoryFanfare = 0,   -- played for winners
	RoundEnd       = 0,   -- played at round end
	AttackSwing    = 0,   -- local feedback for attack
	DashWhoosh     = 0,   -- local feedback for dash
	BlockClank     = 0,   -- local feedback for block
}

-- Animation asset ID placeholders (replace with your own uploaded animation IDs)
ContentConfig.Animations = {
	CelebrationWin   = 0,  -- winner celebration loop
	AttackAnim       = 0,  -- melee attack
	DashAnim         = 0,  -- dash
	BlockAnim        = 0,  -- block hold
	IdleAnim         = 0,  -- optional arena idle override
}

-- Categories available for choice pairs (informational)
ContentConfig.Categories = {
	"Adventure",
	"Fantasy",
	"Elemental",
	"Power",
	"Warriors",
	"Animals",
}

return ContentConfig