local Cell = require("tirenvi.core.cell") -- Core

local log = require("tirenvi.util.log") -- Util

---@alias WidthAction
---| "set"
---| "add"
---| "sub"
---| "auto"
---| "info"
---| "none"

-- =============================================================================
---@class WidthRequest
---@field args string
---@field command "width"|"fit"|"wrap"
---@field operation WidthAction
---@field number integer
---@field cursor_buf CursorBuf
local WidthRequest = {}
WidthRequest.__index = WidthRequest

-- =============================================================================
--#region Private

local map = {
	["="] = "set",
	["+"] = "add",
	["-"] = "sub",
	["?"] = "info",
}

---@param str string
---@return integer
local function get_number(str)
	if not str or str == "" then
		return 1
	end
	local num = tonumber(str)
	if not num or num < 0 then
		error(string.format("%s is not positive number", str))
	end
	return math.max(1, num)
end

---@param self WidthRequest
---@param suffix string[]
local function set_operation(self, suffix)
	local suffixes = table.concat(suffix, "%")
	local regex = string.format("^%s%%s*([%s])(.*)", self.command, suffixes)
	local op, value = self.args:match(regex)
	if not op then
		error(string.format("%s need operator %s", self.command, suffixes))
	end
	self.operation = map[op]
	self.number = get_number(value)
	if self.operation == "info" and #value ~= 0 then
		-- case: Tir width?10
		self.operation = nil
		self.number = nil
	elseif self.operation == "set" and self.number <= 1 then
		-- case: Tir width=
		self.operation = "auto"
		self.number = 0
	end
end

---@param cmd_opts {[string]:any}
---@param cursor_buf CursorBuf
---@param sub_cmd_name string
---@param spec {[string]:any}|nil
---@return WidthRequest|nil
local function try_new(cmd_opts, cursor_buf, sub_cmd_name, spec)
	local self = setmetatable({
		args = cmd_opts.args,
		command = sub_cmd_name,
		operation = "none",
		number = 0,
		cursor_buf = cursor_buf,
	}, WidthRequest)
	if not spec then
		if cmd_opts.args ~= sub_cmd_name then
			return nil
		end
		return self
	end
	set_operation(self, spec.suffix)
	if not self.operation or not self.number then
		return nil
	end
	return self
end

--#endregion
-- =============================================================================
-- Public API

---@param cmd_opts {[string]:any}
---@param cursor_buf CursorBuf
---@param sub_cmd_name string
---@param spec {[string]:any}|nil
---@return WidthRequest|nil
function WidthRequest.new(cmd_opts, cursor_buf, sub_cmd_name, spec)
	local ok, self = pcall(try_new, cmd_opts, cursor_buf, sub_cmd_name, spec)
	if not ok or not self then
		return nil
	end
	return self
end

function WidthRequest:to_cmd()
	return string.format(":<C-u>Tir %s<CR>", self.args)
end

---@param self WidthRequest
---@return string
function WidthRequest:to_string()
	return string.format(
		"WidthRequest %s %s (%d, %d) [%s] %s",
		self.command,
		self.operation or "nil",
		self.cursor_buf.row_cur,
		self.cursor_buf.col_disp,
		self.number or "nil",
		self:to_cmd()
	)
end

---@param self WidthRequest
---@param current integer
---@return integer
function WidthRequest:apply(current)
	local operation = self.operation
	local count = self.number
	if operation == "set" then
		return math.max(count, Cell.MIN_WIDTH)
	elseif operation == "add" then
		return current + count
	elseif operation == "sub" then
		return math.max(current - count, Cell.MIN_WIDTH)
	elseif operation == "auto" then
		return 0
	else
		return current
	end
end

return WidthRequest
