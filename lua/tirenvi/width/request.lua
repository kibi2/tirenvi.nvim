local fn = vim.fn -- Neovim

local Cell = require("tirenvi.core.cell") -- Core

local Range = require("tirenvi.util.range") -- Util
local log = require("tirenvi.util.log")

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
---@field row_cur integer
---@field col_disp integer
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

---@param cmd_opts {[string]:any}
---@return Rect
local function get_selection(cmd_opts)
	local row_range = Range.from_lua_normal(cmd_opts.line1, cmd_opts.line2)
	local is_block = (fn.visualmode() == "\22")
	local col_disp_start, col_disp_end
	if cmd_opts.range > 0 then
		if is_block then
			col_disp_start = fn.virtcol("'<")
			col_disp_end = fn.virtcol("'>")
		else
			col_disp_start = 1
			col_disp_end = math.huge
		end
	else
		local col = fn.virtcol(".")
		col_disp_start = col
		col_disp_end = col
	end
	local col_range = Range.from_lua_normal(col_disp_start, col_disp_end)
	---@type Rect
	return {
		row = row_range,
		col = col_range,
	}
end

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
---@param sub_cmd_name string
---@param spec {[string]:any}|nil
---@return WidthRequest|nil
local function try_new(cmd_opts, sub_cmd_name, spec)
	local rect = get_selection(cmd_opts)
	local row_cur = rect.row.first
	local col_disp = rect.col.first
	local self = setmetatable({
		args = cmd_opts.args,
		command = sub_cmd_name,
		operation = "none",
		number = 0,
		row_cur = row_cur,
		col_disp = col_disp,
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
---@param sub_cmd_name string
---@param spec {[string]:any}|nil
---@return WidthRequest|nil
function WidthRequest.new(cmd_opts, sub_cmd_name, spec)
	local ok, self = pcall(try_new, cmd_opts, sub_cmd_name, spec)
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
		self.row_cur,
		self.col_disp,
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
