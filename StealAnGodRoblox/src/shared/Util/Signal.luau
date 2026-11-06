--[[
	Signal — tiny synchronous signal used for cross-system events on the same side.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handlers = self._handlers
	table.insert(handlers, fn)
	local connection = {}
	function connection.Disconnect()
		local i = table.find(handlers, fn)
		if i then
			table.remove(handlers, i)
		end
	end
	return connection
end

function Signal:Fire(...)
	for _, fn in table.clone(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
