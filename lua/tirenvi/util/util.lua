--- Small utility helpers used across tirenvi modules.
---
--- Notes:
---   - This module contains only pure helper utilities.
---   - No side effects.

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local config = require("tirenvi.config")
local errors = require("tirenvi.util.errors")
local log = require("tirenvi.util.log")


-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

local api = vim.api
local fn = vim.fn
-- private helpers

---@return {[string]:string}
local function collect_reserved_chars()
	local set = {}
	for name, marks in pairs(config.marks) do
		if marks then
			set[marks] = name
		end
	end
	return set
end

---@param fl_lines string[]
---@return string[]
local function find_reserved_marks(fl_lines)
	local char_to_name = collect_reserved_chars()
	local found_names = {}
	for _, line in ipairs(fl_lines) do
		for _, ch in ipairs(M.utf8_chars(line)) do
			local name = char_to_name[ch]
			if name then
				found_names[name] = true
			end
		end
	end
	local result = {}
	for name in pairs(found_names) do
		result[#result + 1] = name
	end
	return result
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param str string
---@return string[]
function M.utf8_chars(str)
	local chars = {}
	local nStr = fn.strchars(str)
	for iStr = 0, nStr - 1 do
		chars[#chars + 1] = fn.strcharpart(str, iStr, 1)
	end
	return chars
end

--- Get file extension.
---@param filename string
---@return string|nil
function M.get_ext(filename)
	return filename:match("^.+%.([^.]+)$")
end

--- Convert string to hex representation (for debugging).
---@param str string
---@return string
function M.to_hex(str)
	local hex = {}
	for i = 1, #str do
		hex[#hex + 1] = string.format("%02X", string.byte(str, i))
	end
	return table.concat(hex, " ")
end

---@param array1 any[]
---@param array2 any[]
function M.extend(array1, array2)
	table.move(array2, 1, #array2, #array1 + 1, array1)
end

---@param fl_lines string[]
---@return nil
function M.assert_no_reserved_marks(fl_lines)
	local found = find_reserved_marks(fl_lines)
	if #found > 0 then
		error(errors.new_domain_error(errors.err_no_usable_characters(found)))
	end
end

---@param line string
---@param str string
---@return boolean
function M.start_with(line, str)
	return line:sub(1, #str) == str
end

---@param line string
---@param str string
---@return boolean
function M.end_with(line, str)
	return line:sub(- #str) == str
end

---@param code string
---@return string
function M.get_termcodes(code)
	return api.nvim_replace_termcodes(code, true, false, true)
end

return M
