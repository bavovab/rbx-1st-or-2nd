local Remotes = script.Parent

local EVENTS = {
	"PhaseChanged",
	"TimerUpdate",
	"ChoiceRevealA",
	"ChoiceRevealB",
	"DarknessBegin",
	"DarknessEnd",
	"TeamAssigned",
	"BattleStart",
	"PlayerEliminated",
	"VictoryAnnounced",
	"CelebrationStart",
	"RoundResult",
	"HUDMessage",
	"HPUpdate",
	"SubmitChoice",
	"CombatInput",
}

for _, name in ipairs(EVENTS) do
	if not Remotes:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = Remotes
	end
end