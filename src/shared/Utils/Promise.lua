--//global_variables

local promise_module = {}
promise_module.__index = promise_module
local event_subclass = {}
event_subclass.__index = event_subclass

--//modular_functions

function promise_module.New(call_back)
	return setmetatable({
		CallBack = call_back,
	}, promise_module)
end

function promise_module:Then(sucess_function, fail_function)
	self.CallBack(sucess_function, fail_function)
	return self
end

--//promise_event_subclass

function promise_module.WrapEvent(event_sent, wait_time)
	local main_object = setmetatable({
		IsConnected = true,
		__Connection = nil,
	}, event_subclass)
	main_object.Promise = promise_module.New(function(on_resolve, on_error)
		main_object.__Connection = event_sent:Connect(function()
			return (main_object:IsValid() and on_resolve())
		end)
		return task.delay(wait_time, function()
			return (main_object:IsValid() and (on_error and on_error() or on_resolve()))
		end)
	end)
	return main_object
end

function event_subclass:Then(sucess_function, fail_function)
	self.Promise:Then(sucess_function, fail_function)
	return self
end

function event_subclass:IsValid()
	if not self.IsConnected then
		return
	end
	self:Disconnect()
	return true
end

function event_subclass:Disconnect()
	if not self.IsConnected then
		return
	end
	self.IsConnected = false
	self.Promise = nil
	local object_connection: RBXScriptConnection = self.__Connection
	if object_connection and object_connection.Connected then
		object_connection:Disconnect()
	end
	self.__Connection = nil
end

return {
	New = promise_module.New,
	WrapEvent = promise_module.WrapEvent,
}
