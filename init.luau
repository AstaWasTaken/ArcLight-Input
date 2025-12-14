--[[
	ArcLightInput - Gameplay Input Manager
	
	A complete input management system for in-game actions.
	Handles keybinds, combos, UI, buffering, priority blocking, and more.
	
	FEATURES & EXAMPLES:
	
	1. Basic keyboard/touch input:
		local Attack = Input.Register("Attack", 10):Define(Enum.KeyCode.Q)
		Attack.OnBegan:Connect(function() player:Attack() end)
	
	2. Multiple binds per action:
		Attack:Define(Enum.UserInputType.Touch)
	
	3. Input buffering (queue while animating):
		Attack:EnableBuffer(0.3)
	
	4. Combo detection (Q-W-E within 1 second):
		local Ult = Input.Register("Ultimate", 9)
			:DefineSequence({Enum.KeyCode.Q, Enum.KeyCode.W, Enum.KeyCode.E}, 1)
	
	5. UI button binding:
		local Shop = Input.Register("Shop", 8):DefineUI(script.Parent.ShopBtn)
	
	6. Critical priority (never blocked):
		local Menu = Input.Register("Menu", Input.CRITICAL_PRIORITY)
			:Define(Enum.KeyCode.Escape)
	
	7. Runtime remap:
		Attack:Remap(Enum.KeyCode.E)
	
	8. Temporary input reader (3 presses or 5s timeout):
		Input.ReadInput("Bind", 3, 5):Connect(function(input)
			print("Bound to:", input.KeyCode)
		end)
	
	9. Enable/disable actions:
		Attack:Disable()
		task.wait(2)
		Attack:Enable()
	
	10. Cleanup:
		Attack:Destroy()
	
	11. Get device type (PC/Mobile/Console/GamePad):
		local device = Input.GetDevice()
	
	12. Get telemetry:
		local stats = Input.GetTelemetry()
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Package = script.Package
local Core = script.Core

local Trove = require(Package.trove)
local Signal = require(Package.goodsignal)

local Types = require(Core.Types)
local DeviceDetector = require(Core.DeviceDetector)
local ActionRegistry = require(Core.ActionRegistry)
local InputProcessor = require(Core.InputProcessor)
local BufferSystem = require(Core.BufferSystem)

export type Device = Types.Device
export type Input = Types.Input
export type Action = Types.Action

local InputManager = {}
local GlobalCleaner = Trove.new()
local SortedPool = {}
local PoolSize = 5
local User = Players.LocalPlayer

InputManager.CRITICAL_PRIORITY = ActionRegistry.GetConfig().CriticalPriority

local function GetSortedActions()
	local sorted = table.remove(SortedPool) or table.create(32)
	table.clear(sorted)

	for _, action in ActionRegistry.GetAll() do
		if action.Enabled then
			table.insert(sorted, action)
		end
	end

	table.sort(sorted, function(a, b)
		return a.Priority > b.Priority
	end)

	return sorted
end

local function ReturnSorted(sorted)
	if #SortedPool < PoolSize then
		table.clear(sorted)
		table.insert(SortedPool, sorted)
	end
end

local function ProcessInput(input: InputObject, state: Enum.UserInputState)
	local sorted = GetSortedActions()

	pcall(function()
		for _, action in sorted do
			if not action.Bindings then
				continue
			end

			for _, binding in action.Bindings do
				if not InputProcessor.IsMatch(binding, input) then
					continue
				end

				if state == Enum.UserInputState.Begin then
					InputProcessor.HandleBegin(action, input, sorted)
					ActionRegistry.IncrementTotalInputs()
				elseif state == Enum.UserInputState.End then
					InputProcessor.HandleEnd(action, input, sorted)
				end

				return
			end
		end
	end)

	ReturnSorted(sorted)
end

function InputManager.Register(ID: string, Priority: number?): Action
	return ActionRegistry.Create(ID, Priority)
end

function InputManager.ReadInput(ID: string, Count: number?, Timeout: number?)
	local signal = Signal.new()
	local count = 0
	local max = Count or 1
	local destroyed = false

	local temp = InputManager.Register(ID, 999)

	local conn
	conn = temp.OnBegan:Connect(function(input)
		if destroyed then
			return
		end

		count += 1
		signal:Fire(input)

		if count >= max then
			destroyed = true
			conn:Disconnect()
			signal:DisconnectAll()
			temp:Destroy()
		end
	end)

	if Timeout and Timeout > 0 then
		task.delay(Timeout, function()
			if not destroyed then
				destroyed = true
				conn:Disconnect()
				signal:DisconnectAll()
				temp:Destroy()
			end
		end)
	end

	return signal
end

function InputManager.GetDevice(): Device
	return DeviceDetector.Detect()
end

function InputManager.GetTelemetry()
	return ActionRegistry.GetTelemetry()
end

task.defer(function()
	while true do
		task.wait(ActionRegistry.GetConfig().BufferCleanupInterval)
		BufferSystem.CleanExpired()
	end
end)

GlobalCleaner:Add(UserInputService.InputBegan:Connect(function(input, processed)
	if not processed then
		ProcessInput(input, Enum.UserInputState.Begin)
	end
end))

GlobalCleaner:Add(UserInputService.InputEnded:Connect(function(input, processed)
	if not processed then
		ProcessInput(input, Enum.UserInputState.End)
	end
end))

GlobalCleaner:Add(UserInputService.GamepadConnected:Connect(DeviceDetector.Reset))
GlobalCleaner:Add(UserInputService.GamepadDisconnected:Connect(DeviceDetector.Reset))

if User then
	GlobalCleaner:Add(User.AncestryChanged:Connect(function()
		if not User.Parent then
			GlobalCleaner:Destroy()
		end
	end))
end

return InputManager
