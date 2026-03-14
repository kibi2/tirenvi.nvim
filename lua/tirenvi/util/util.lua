--- Small utility helpers used across tirenvi modules.
---
--- Notes:
---   - This module contains only pure helper utilities.
---   - No side effects.

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local config = require("tirenvi.config")
local buffer = require("tirenvi.state.buffer")
local errors = require("tirenvi.util.errors")


-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

local fn = vim.fn
-- private helpers

--- Get parser configuration for a file.
---@param filename string
---@return Parser | nil
local function get_parser_for_file(filename)
	local ext = M.get_ext(filename)
	if not ext then
		return nil
	end
	return config.parser_map[ext]
end

---@param str string
---@return string[]
local function utf8_chars(str)
	local chars = {}
	local nStr = fn.strchars(str)
	for iStr = 0, nStr - 1 do
		chars[#chars + 1] = fn.strcharpart(str, iStr, 1)
	end
	return chars
end

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
		for _, ch in ipairs(utf8_chars(line)) do
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

--- Get file extension.
---@param filename string
---@return string | nil
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

---@param line string
---@return boolean
function M.has_pipe(line)
	return line:find(config.marks.pipe) ~= nil
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

---@param bufnr number
---@param new_path string|nil
---@param old_path string|nil
---@return Parser
function M.get_parser(bufnr, new_path, old_path)
	if new_path == nil then
		new_path = buffer.get_file_path(bufnr)
	end
	local file_path = new_path
	local parser = get_parser_for_file(file_path)
	if not parser and old_path then
		file_path = old_path
		parser = get_parser_for_file(file_path)
	end
	if parser == nil then
		error(errors.new_domain_error(""))
	end
	if fn.executable(parser.executable) ~= 1 then
		error(errors.new_domain_error(errors.not_found_parser_error(parser)))
	end
	return parser
end

return M
