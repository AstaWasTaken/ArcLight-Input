local Trove = require(script.Parent.Parent.Package.trove)
local Signal = require(script.Parent.Parent.Package.goodsignal)
local Types = require(script.Parent.Types)
local UIIntegration = require(script.Parent.UIIntegration)
local BufferSystem = require(script.Parent.BufferSystem)
local SequenceDetector = require(script.Parent.SequenceDetector)
local InputProcessor = require(script.Parent.InputProcessor)

type Action = Types.Action
type Input = Types.Input

local ActionRegistry = {}
local Registry = {}
local Telemetry = { totalInputs = 0, droppedInputs = 0, activeActions = 0 }
local Config = {
	MaxActiveInputs = 100,
	CriticalPriority = 1000,
	MaxBufferDuration = 2,
	MaxSequenceLength = 10,
}

local ActionMeta = {}
ActionMeta.__index = ActionMeta

function ActionMeta:Define(Input: Input | { Input })
	if self.IsSequenceMode then
		warn(`[InputManager] Cannot mix Define with Sequence on "{self.ID}"`)
		return self
	end

	table.insert(self.Bindings, Input)
	return self
end

function ActionMeta:DefineUI(GuiObject: GuiObject)
	self.UIBinding = GuiObject
	UIIntegration.Setup(self, GuiObject)
	return self
end

function ActionMeta:DefineSequence(Inputs: { Input }, Window: number?)
	if #self.Bindings > 0 then
		warn(`[InputManager] Clear bindings before using Sequence on "{self.ID}"`)
		return self
	end

	if #Inputs > Config.MaxSequenceLength then
		Inputs = { table.unpack(Inputs, 1, Config.MaxSequenceLength) }
	end

	self.IsSequenceMode = true
	self.SequenceBinding = {
		inputs = Inputs,
		window = Window or 1,
	}

	for _, input in Inputs do
		table.insert(self.Bindings, input)
	end

	return self
end

function ActionMeta:Undefine(Input: Input?)
	if not Input then
		self.Bindings = {}
		self.IsSequenceMode = false
		self.SequenceBinding = nil
		return self
	end

	for i = #self.Bindings, 1, -1 do
		if self.Bindings[i] == Input then
			table.remove(self.Bindings, i)
		end
	end
	return self
end

function ActionMeta:UndefineUI()
	self.UIBinding = nil
	return self
end

function ActionMeta:Remap(Input: Input | { Input })
	self.Bindings = { Input }
	self.IsSequenceMode = false
	self.SequenceBinding = nil
	return self
end

function ActionMeta:Enable()
	self.Enabled = true
	return self
end

function ActionMeta:Disable()
	self.Enabled = false
	InputProcessor.ClearState(self.ID)
	BufferSystem.SetProcessing(self.ID, false)
	return self
end

function ActionMeta:EnableBuffer(Duration: number?)
	if self.IsSequenceMode then
		return self
	end

	self.BufferEnabled = true
	if Duration then
		self.BufferDuration = math.clamp(Duration, 0.01, Config.MaxBufferDuration)
	end
	return self
end

function ActionMeta:ConsumeBuffer()
	return BufferSystem.Consume(self)
end

function ActionMeta:GetBufferedInput()
	-- Alias for clarity; returns true if a buffered input was consumed
	return BufferSystem.Consume(self)
end

function ActionMeta:Destroy()
	if self.Cleaner then
		Telemetry.activeActions -= 1
		self.Cleaner:Destroy()
	end
end

function ActionRegistry.Create(ID: string, Priority: number?): Action
	if Registry[ID] then
		return Registry[ID] :: Action
	end

	local self = setmetatable({
		ID = ID,
		Priority = Priority or 0,
		Bindings = {},
		UIBinding = nil,
		SequenceBinding = nil,
		IsSequenceMode = false,
		Enabled = true,
		BufferEnabled = false,
		BufferDuration = 0.2,
		Cleaner = Trove.new(),
		OnBegan = Signal.new(),
		OnEnded = Signal.new(),
	}, ActionMeta)

	self.Cleaner:Add(self.OnBegan)
	self.Cleaner:Add(self.OnEnded)
	self.Cleaner:Add(function()
		Registry[ID] = nil
		InputProcessor.ClearState(ID)
		BufferSystem.Clear(ID)
		SequenceDetector.Clear(ID)
	end)

	Registry[ID] = self
	Telemetry.activeActions += 1
	return self :: Action
end

function ActionRegistry.Get(ID: string): Action?
	return Registry[ID]
end

function ActionRegistry.GetAll()
	return Registry
end

function ActionRegistry.GetTelemetry()
	return {
		totalInputs = Telemetry.totalInputs,
		droppedInputs = Telemetry.droppedInputs,
		activeActions = Telemetry.activeActions,
		activeInputs = InputProcessor.GetActiveCount(),
	}
end

function ActionRegistry.IncrementTotalInputs()
	Telemetry.totalInputs += 1
end

function ActionRegistry.IncrementDroppedInputs()
	Telemetry.droppedInputs += 1
end

function ActionRegistry.GetConfig()
	return Config
end

return ActionRegistry
