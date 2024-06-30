local		TWEEN									=		game:GetService("TweenService")
local		SGUI									=		game:GetService("StarterGui")

local		TeleportScreen							=		script.Parent
local		Bars									=		TeleportScreen:WaitForChild("Bars")
local		Label									=		TeleportScreen:WaitForChild("Label")
local		Background								=		TeleportScreen:WaitForChild("Background")
local		ShutSound								=		TeleportScreen:WaitForChild("ShutSound")

task.spawn(function()
		local		Count							=		0
		while		task.wait(.7) do
				Count							+=		1
				Label.Text						=		if Count == 1 then "Wait a moment." elseif Count == 2 then "Wait a moment.." else "Wait a moment..."
				if		Count >= 3 then
						Count					=		0
				end
		end
end)

ShutSound:Play()
TWEEN:Create(Bars, TweenInfo.new(.3, Enum.EasingStyle.Bounce), {Position = UDim2.fromScale(.5, .5)}):Play()
TWEEN:Create(Background, TweenInfo.new(4), {Transparency = 0}):Play()
task.wait(.3)
TWEEN:Create(Label, TweenInfo.new(3), {TextTransparency = 0}):Play()
SGUI:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)