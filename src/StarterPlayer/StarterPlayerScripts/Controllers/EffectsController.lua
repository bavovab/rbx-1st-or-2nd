-- EffectsController.lua
-- Generic UI tween helpers and visual feedback utilities for client controllers.

local TweenService = game:GetService("TweenService")

local EffectsController = {}

local function MakeTweenInfo(duration, style, direction)
	return TweenInfo.new(
		duration or 0.3,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)
end

-- Fade a GuiObject to a target transparency
function EffectsController.FadeTo(object, targetTrans, duration, callback)
	if not object then return end
	local tween = TweenService:Create(object, MakeTweenInfo(duration), {
		BackgroundTransparency = targetTrans
	})
	tween:Play()
	if callback then
		tween.Completed:Connect(callback)
	end
	return tween
end

-- Tween a GuiObject's BackgroundColor3
function EffectsController.ColorTo(object, color, duration)
	if not object then return end
	local tween = TweenService:Create(object, MakeTweenInfo(duration), {
		BackgroundColor3 = color
	})
	tween:Play()
	return tween
end

-- Tween a GuiObject's Size
function EffectsController.SizeTo(object, targetSize, duration, style)
	if not object then return end
	local tween = TweenService:Create(
		object,
		MakeTweenInfo(duration, style or Enum.EasingStyle.Back),
		{ Size = targetSize }
	)
	tween:Play()
	return tween
end

-- Tween a GuiObject's Position
function EffectsController.PositionTo(object, targetPos, duration)
	if not object then return end
	local tween = TweenService:Create(object, MakeTweenInfo(duration), {
		Position = targetPos
	})
	tween:Play()
	return tween
end

-- Tween TextLabel text color
function EffectsController.TextColorTo(label, color, duration)
	if not label then return end
	local tween = TweenService:Create(object, MakeTweenInfo(duration), {
		TextColor3 = color
	})
	tween:Play()
	return tween
end

-- Pulse scale up then back (for countdown numbers)
function EffectsController.PulseScale(object, scale, duration)
	if not object then return end
	local origSize = object.Size
	local bigSize  = UDim2.new(
		origSize.X.Scale * scale, origSize.X.Offset,
		origSize.Y.Scale * scale, origSize.Y.Offset
	)
	local t1 = TweenService:Create(object, MakeTweenInfo(duration * 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = bigSize })
	local t2 = TweenService:Create(object, MakeTweenInfo(duration * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),  { Size = origSize })
	t1:Play()
	t1.Completed:Connect(function()
		t2:Play()
	end)
end

-- Show a frame by tweening transparency from 1 to 0
function EffectsController.ShowFrame(frame, duration)
	if not frame then return end
	frame.Visible = true
	frame.BackgroundTransparency = 1
	EffectsController.FadeTo(frame, 0, duration or 0.3)
end

-- Hide a frame by tweening transparency from current to 1, then Visible=false
function EffectsController.HideFrame(frame, duration, callback)
	if not frame then return end
	EffectsController.FadeTo(frame, 1, duration or 0.3, function()
		frame.Visible = false
		if callback then callback() end
	end)
end

-- Slide a frame in from offscreen (side = "Left"|"Right"|"Top"|"Bottom")
function EffectsController.SlideIn(frame, side, duration)
	if not frame then return end
	local startPos
	if side == "Left" then
		startPos = UDim2.new(-1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
	elseif side == "Right" then
		startPos = UDim2.new(2, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
	elseif side == "Top" then
		startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, -1, 0)
	else
		startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 2, 0)
	end
	local endPos = frame.Position
	frame.Position = startPos
	frame.Visible  = true
	EffectsController.PositionTo(frame, endPos, duration or 0.4)
end

return EffectsController