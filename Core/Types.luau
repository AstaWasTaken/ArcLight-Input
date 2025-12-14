export type Device = "PC" | "Mobile" | "Console" | "GamePad"
export type Input = Enum.KeyCode | Enum.UserInputType

export type Action = {
	ID: string,
	Priority: number,
	Bindings: { Input },
	Enabled: boolean,
	Cleaner: any,
	OnBegan: any,
	OnEnded: any,
	UIBinding: GuiObject?,
	SequenceBinding: SequenceConfig?,
	IsSequenceMode: boolean,
	BufferEnabled: boolean,
	BufferDuration: number,
	Define: (self: Action, Input: Input | { Input }) -> Action,
	DefineUI: (self: Action, GuiObject: GuiObject) -> Action,
	DefineSequence: (self: Action, Inputs: { Input }, Window: number?) -> Action,
	Undefine: (self: Action, Input: Input?) -> Action,
	UndefineUI: (self: Action) -> Action,
	Remap: (self: Action, Input: Input | { Input }) -> Action,
	Enable: (self: Action) -> Action,
	Disable: (self: Action) -> Action,
	EnableBuffer: (self: Action, Duration: number?) -> Action,
	GetBufferedInput: (self: Action) -> boolean,
	Destroy: (self: Action) -> (),
}

export type SequenceConfig = {
	inputs: { Input },
	window: number,
}

export type SequenceState = {
	index: number,
	lastTime: number,
}

export type Telemetry = {
	totalInputs: number,
	droppedInputs: number,
	activeActions: number,
}

export type Config = {
	MaxActiveInputs: number,
	CriticalPriority: number,
	MaxBufferDuration: number,
	MaxSequenceLength: number,
	BufferCleanupInterval: number,
	DebugMode: boolean,
}

return {}
