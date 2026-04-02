-- Remotes/init.server.lua
-- Creates all RemoteEvents and RemoteFunctions inside ReplicatedStorage.Remotes
-- at runtime so clients can always find them on join.

local Remotes = script.Parent  -- this script IS the Remotes folder object

local EVENTS = {
	-- Server -> Client
	"PhaseChanged",        -- (phaseName: string, data: table)
	"TimerUpdate",         -- (secondsLeft: number)
	"ChoiceRevealA",       -- (choiceData: table)
	"ChoiceRevealB",       -- (choiceData: table)
	"DarknessBegin",       -- ()
	"DarknessEnd",         -- ()
	"TeamAssigned",        -- (teamName: string)
	"BattleStart",         -- (teamName: string, enemyTeam: string)
	"PlayerEliminated",    -- (playerName: string)
	"VictoryAnnounced",    -- (winnerTeam: string, reason: string, isDraw: bool)
	"CelebrationStart",    -- (winnerTeam: string)
	"RoundResult",         -- (resultData: table)
	"HUDMessage",          -- (message: string, duration: number)
	"HPUpdate",            -- (currentHP: number, maxHP: number)

	-- Client -> Server
	"SubmitChoice",        -- (side: string)  "Left" | "Right"
	"CombatInput",         -- (action: string, targetId: number|nil)
}

for _, name in ipairs(EVENTS) do
	if not Remotes:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = Remotes
	end
end