local UserInputService = game:GetService("UserInputService")
local Trove = require(script.Parent.Parent.Package.trove)
local Types = require(script.Parent.Types)

type Action = Types.Action

local UIIntegration = {}

local function SetupButton(action: Action, button: GuiButton, cleaner)
	local processing = false

	cleaner:Add(button.Activated:Connect(function()
		if processing or not action.Enabled then
			return
		end

		processing = true
		action.OnBegan:Fire(button)

		task.wait()

		action.OnEnded:Fire(button)
		processing = false
	end))

	cleaner:Add(function()
		action.OnEnded:Fire(button)
	end)
end

local function SetupFrame(action: Action, frame: GuiObject, cleaner)
	local function onBegan(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if not action.Enabled then
			return
		end

		action.OnBegan:Fire(input)
	end

	local function onEnded(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		action.OnEnded:Fire(input)
	end

	cleaner:Add(frame.InputBegan:Connect(onBegan))
	cleaner:Add(frame.InputEnded:Connect(onEnded))

	cleaner:Add(function()
		action.OnEnded:Fire(frame)
	end)
end

function UIIntegration.Setup(action: Action, gui: GuiObject)
	local cleaner = Trove.new()
	action.Cleaner:Add(cleaner)

	local conn
	conn = gui.AncestryChanged:Connect(function()
		if not gui.Parent then
			action.OnEnded:Fire(gui)
			action:UndefineUI()
			if conn then
				conn:Disconnect()
			end
		end
	end)
	cleaner:Add(conn)

	if gui:IsA("GuiButton") then
		SetupButton(action, gui, cleaner)
	elseif gui:IsA("GuiObject") then
		SetupFrame(action, gui, cleaner)
	end
end

return UIIntegration
