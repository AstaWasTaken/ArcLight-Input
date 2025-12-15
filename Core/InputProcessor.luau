local UserInputService = game:GetService("UserInputService")
local Types = require(script.Parent.Types)
local BufferSystem = require(script.Parent.BufferSystem)
local SequenceDetector = require(script.Parent.SequenceDetector)

type Action = Types.Action

local InputProcessor = {}
local ActiveStates = {}
local BlockedStates = {}

function InputProcessor.IsMatch(binding: any, input: InputObject): boolean
	if typeof(binding) ~= "table" then
		return input.KeyCode == binding or input.UserInputType == binding
	end

	local strict = binding.Strict
	local matches = 0

	for _, key in binding do
		if
			typeof(key) == "EnumItem"
			and (input.KeyCode == key or input.UserInputType == key or UserInputService:IsKeyDown(key))
		then
			matches += 1
			if not strict then
				return true
			end
		end
	end

	return strict and matches == #binding
end

function InputProcessor.BlockLower(action: Action, sorted)
	for _, other in sorted do
		if other.Priority < action.Priority then
			BlockedStates[other.ID] = true
		end
	end
end

function InputProcessor.UnblockLower(action: Action, sorted)
	for id, active in ActiveStates do
		if active and sorted[id] and sorted[id].Priority >= action.Priority then
			return
		end
	end

	for _, other in sorted do
		if other.Priority < action.Priority then
			BlockedStates[other.ID] = nil
		end
	end
end

function InputProcessor.HandleBegin(action: Action, input: InputObject, sorted)
	if BlockedStates[action.ID] then
		return
	end

	-- Buffer the input when it begins. This ensures we have a record of the press
	if action.BufferEnabled then
		BufferSystem.Create(action)
	end

	if action.IsSequenceMode then
		if SequenceDetector.Process(action, input) then
			action.OnBegan:Fire(input)
			InputProcessor.BlockLower(action, sorted)
		end
		return
	end

	-- Note: Removed the "if ActiveStates then Create" block because we did it above
	if ActiveStates[action.ID] then
		return
	end

	ActiveStates[action.ID] = true
	action.OnBegan:Fire(input)
	InputProcessor.BlockLower(action, sorted)
end


function InputProcessor.HandleEnd(action: Action, input: InputObject, sorted)
	if not ActiveStates[action.ID] then
		return
	end

	if BufferSystem.IsProcessing(action.ID) then
		return
	end

	ActiveStates[action.ID] = false
	action.OnEnded:Fire(input)

	-- 2. DISABLE Auto-Consume on KeyUp
	-- ConsumeBuffer controlled by user via Attack:ConsumeBuffer() , not the KeyUp event.

	--[[ 
	if BufferSystem.Consume(action) then
		BufferSystem.SetProcessing(action.ID, true)
		task.defer(function()
			BufferSystem.SetProcessing(action.ID, false)
			if action.Enabled and not BlockedStates[action.ID] and not ActiveStates[action.ID] then
				ActiveStates[action.ID] = true
				action.OnBegan:Fire(input)
			end
		end)
	else
		InputProcessor.UnblockLower(action, sorted)
	end
	--]]

	-- Ensure we still unblock lower priority actions
	InputProcessor.UnblockLower(action, sorted)
end

function InputProcessor.ClearState(actionId: string)
	ActiveStates[actionId] = nil
	BlockedStates[actionId] = nil
end

function InputProcessor.IsBlocked(actionId: string): boolean
	return BlockedStates[actionId] == true
end

function InputProcessor.IsActive(actionId: string): boolean
	return ActiveStates[actionId] == true
end

function InputProcessor.SetActive(actionId: string, active: boolean)
	ActiveStates[actionId] = active or nil
end

function InputProcessor.GetActiveCount(): number
	local count = 0
	for _ in ActiveStates do
		count += 1
	end
	return count
end

return InputProcessor
