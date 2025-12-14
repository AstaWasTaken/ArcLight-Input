local Types = require(script.Parent.Types)

type Action = Types.Action
type SequenceState = Types.SequenceState

local SequenceDetector = {}
local SequenceStates = {}

function SequenceDetector.Process(action: Action, input: InputObject): boolean
	if not action.SequenceBinding then
		return false
	end

	local seqId = action.ID .. "_seq"
	local state = SequenceStates[seqId]

	if not state then
		state = { index = 0, lastTime = 0 }
		SequenceStates[seqId] = state
	end

	local now = os.clock()
	if now - state.lastTime > action.SequenceBinding.window then
		state.index = 0
	end

	local expected = action.SequenceBinding.inputs[state.index + 1]
	if input.KeyCode == expected or input.UserInputType == expected then
		state.index += 1
		state.lastTime = now

		if state.index >= #action.SequenceBinding.inputs then
			state.index = 0
			return true
		end
	else
		state.index = 0
	end

	return false
end

function SequenceDetector.Clear(actionId: string)
	SequenceStates[actionId .. "_seq"] = nil
end

return SequenceDetector
