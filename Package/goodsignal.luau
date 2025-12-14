--------------------------------------------------------------------------------
--               Batched Yield-Safe Signal Implementation                     --
-- This is a Signal class which has effectively identical behavior to a       --
-- normal RBXScriptSignal, with the only difference being a couple extra      --
-- stack frames at the bottom of the stack trace when an error is thrown.     --
-- This implementation caches runner coroutines, so the ability to yield in   --
-- the signal handlers comes at minimal extra cost over a naive signal        --
-- implementation that either always or never spawns a thread.                --
--                                                                            --
-- API:                                                                       --
--   local Signal = require(THIS MODULE)                                      --
--   local sig = Signal.new()                                                 --
--   local connection = sig:Connect(function(arg1, arg2, ...) ... end)        --
--   sig:Fire(arg1, arg2, ...)                                                --
--   connection:Disconnect()                                                  --
--   sig:DisconnectAll()                                                      --
--   local arg1, arg2, ... = sig:Wait()                                       --
--                                                                            --
-- Licence:                                                                   --
--   Licenced under the MIT licence.                                          --
--                                                                            --
-- Authors:                                                                   --
--   stravant - July 31st, 2021 - Created the file.                           --
--   sleitnick - August 3rd, 2021 - Modified for Knit.                        --
--   stackyz - July 23rd, 2024 - Modified for Echo.                           --
--------------------------------------------------------------------------------
--!nocheck

-- The currently idle thread to run the next handler on
local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil

	fn(...)

	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)

	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

-- Connection class
local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	if self.Connected == false then
		return
	end

	self.Connected = false

	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

function Connection:Destroy()
	return self:Disconnect()
end

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> (),
}

-- Signal class
local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
	return setmetatable({
		_handlerListHead = false,
	}, Signal) :: any
end

function Signal.Is(signal): boolean
	return if type(signal) == "table" then getmetatable(signal) == Signal else false
end

function Signal.Wrap<T...>(signal): Signal<T...>
	local newSignal = Signal.new()

	signal:Connect(function(...)
		newSignal:Fire(...)
	end)

	return newSignal
end

function Signal:Connect(fn)
	local connection = setmetatable({
		Connected = true,

		_signal = self,
		_fn = fn,
		_next = false,
		_yieldedThread = nil
	}, Connection)

	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end

	return connection
end

function Signal:DisconnectAll()
	local item = self._handlerListHead
	while item do
		if item.Connected then
			item.Connected = false
			
			local thread = item._yieldedThread

			if thread and coroutine.status(thread) == "suspended" then
				warn(debug.traceback(thread, "signal disconnected; yielded thread cancelled", 2))
				task.cancel(thread)
			end
		end

		item = item._next
	end
end

function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		task.defer(function(cn, ...)
			if cn.Connected == true then
				cn._fn(...)
			end
		end, item, ...)

		item = item._next
	end
end

function Signal:FireImmediate(...)
	local item = self._handlerListHead
	while item do
		if item.Connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end

			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	local cn
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	cn._yieldedThread = waitingCoroutine
	return coroutine.yield()
end

function Signal:Once(fn)
	local cn
	cn = self:Connect(function(...)
		if cn.Connected then
			cn:Disconnect()
		end
		fn(...)
	end)
	return cn
end

function Signal:Destroy()
	self:DisconnectAll()

	table.clear(self)
	setmetatable(self, nil)
end

return table.freeze({
	new = Signal.new,
	Is = Signal.Is,
	Wrap = Signal.Wrap,
})
