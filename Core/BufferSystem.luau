local Types = require(script.Parent.Types)

type Action = Types.Action

local BufferSystem = {}
local BufferStates = {}
local ProcessingBuffer = {}

function BufferSystem.Create(action: Action)
	if not action.BufferEnabled then
		return
	end

	local bufferId = action.ID .. "_buffer"
	local existing = BufferStates[bufferId]
	if existing and os.clock() < existing then
		return
	end

	BufferStates[bufferId] = os.clock() + action.BufferDuration
end

function BufferSystem.Consume(action: Action): boolean
	if not action.BufferEnabled then
		return false
	end

	local bufferId = action.ID .. "_buffer"
	local bufferTime = BufferStates[bufferId]
	
	if bufferTime and os.clock() < bufferTime then
		BufferStates[bufferId] = nil
		return true
	end

	if bufferTime then
		BufferStates[bufferId] = nil
	end

	return false
end

function BufferSystem.IsProcessing(actionId: string): boolean
	return ProcessingBuffer[actionId] == true
end

function BufferSystem.SetProcessing(actionId: string, processing: boolean)
	ProcessingBuffer[actionId] = processing or nil
end

function BufferSystem.CleanExpired()
	local now = os.clock()
	for id, bufferTime in BufferStates do
		if bufferTime < now then
			BufferStates[id] = nil
		end
	end
end

function BufferSystem.Clear(actionId: string)
	BufferStates[actionId .. "_buffer"] = nil
	ProcessingBuffer[actionId] = nil
end

return BufferSystem
