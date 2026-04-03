-- ModuleScript
local Players = game:GetService("Players")

local CelebrationController = {}

local localPlayer = Players.LocalPlayer

function CelebrationController.Init()
	-- Не подписывается ни на какие ремоуты.
	-- Реакции приходят через PlayCelebration в ClientBootstrap.
end

function CelebrationController.PlayCelebration(animId)
	if not animId or animId == 0 then return end
	local char = localPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local animInstance = Instance.new("Animation")
	animInstance.AnimationId = "rbxassetid://" .. tostring(animId)

	local ok, track = pcall(function()
		return hum:LoadAnimation(animInstance)
	end)
	if ok and track then
		track:Play()
		task.delay(math.max(track.Length, 0.1) + 0.1, function()
			if track.IsPlaying then track:Stop() end
		end)
	end
end

function CelebrationController.PlaySound(sfxId)
	if not sfxId or sfxId == 0 then return end
	local char = localPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(sfxId)
	sound.Volume  = 0.8
	sound.Parent  = hrp
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return CelebrationController