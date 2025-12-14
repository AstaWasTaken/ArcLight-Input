local UserInputService = game:GetService("UserInputService")
local Types = require(script.Parent.Types)

type Device = Types.Device

local DeviceDetector = {}
local CurrentDevice: Device? = nil

function DeviceDetector.Detect(): Device
	if CurrentDevice then
		return CurrentDevice
	end

	local pref = UserInputService.PreferredInput
	CurrentDevice = if pref == Enum.PreferredInput.Gamepad
		then "GamePad"
		elseif pref == Enum.PreferredInput.Touch then "Mobile"
		elseif pref == Enum.PreferredInput.KeyboardAndMouse then "PC"
		else "Console"

	return CurrentDevice
end

function DeviceDetector.Reset()
	CurrentDevice = nil
end

function DeviceDetector.GetCurrent(): Device?
	return CurrentDevice
end

return DeviceDetector
