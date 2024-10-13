--//global_variables

local maid_module = {}
maid_module.__index = maid_module

--//cleaning_fucntions

local clean_functions = {}

clean_functions["function"] = function(callBack: () -> nil)
	return callBack()
end

function clean_functions.RBXScriptConnection(connection)
	return connection:Disconnect()
end

function clean_functions.Instance(object)
	return object:Destroy()
end

function clean_functions.table(table_send)
	local custom_type = table_send.__Type
	if custom_type then
		local modified_function = clean_functions[custom_type]
		if modified_function then
			return modified_function(table_send)
		end
	end
	return maid_module.Destroy(table_send)
end

local function destroy_data(value: any)
	local func_call = clean_functions[typeof(value)]
	if func_call then
		return task.spawn(func_call, value)
	end
end

--//modular_functions

function maid_module.Create()
	return setmetatable({}, maid_module)
end

function maid_module:Add(value_add: any)
	if value_add == nil then
		return
	end
	if self.Destroyed then
		return destroy_data(value_add)
	end
	table.insert(self, value_add)
	return value_add
end

function maid_module:AddMultiple(...)
	for _, value in ipairs({ ... }) do
		if self.Destroyed then
			destroy_data(value)
			continue
		end
		table.insert(self, value)
	end
end

function maid_module:Destroy()
	self.Destroyed = true
	self.DebrisFlag = nil
	local index, value = next(self)
	while value ~= nil do
		destroy_data(value)
		self[index] = nil
		index, value = next(self, index)
	end
end

function maid_module:Clear()
	local index, value = next(self)
	while value ~= nil do
		destroy_data(value)
		self[index] = nil
		index, value = next(self, index)
	end
end

function maid_module:Remove(valueRemove: any)
	local valueIndex = table.find(self, valueRemove)
	return (valueIndex and table.remove(self, valueIndex))
end

function maid_module:RemoveIndex(indexRemove: number): any
	local valueReturn: any = self[indexRemove]
	table.remove(self, indexRemove)
	return valueReturn
end

function maid_module:Debris(time_delay)
	assert(type(time_delay) == "number", ("Expected number, got " .. type(time_delay)))
	local unique_flag = tostring({})
	self.DebrisFlag = unique_flag
	return task.delay(time_delay, function()
		if self.DebrisFlag == unique_flag then
			return self:Destroy()
		end
	end)
end

return maid_module
