--- helper.lua
--- Small utility helpers used across tirenvi modules.
---
--- Purpose:
---   - File extension detection
---   - Parser lookup by file extension
---   - Hex string conversion (debug use)
---   - Domain error construction
---   - Replacement pair construction
---
--- Notes:
---   - This module contains only pure helper utilities.
---   - No side effects.

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local config = require("tirenvi.config")
local errors = require("tirenvi.errors")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

--- Get file extension.
---@param filename string
---@return string | nil
function M.get_ext(filename)
	return filename:match("^.+%.([^.]+)$")
end

--- Get parser configuration for a file.
---@param filename string
---@return Parser | nil
function M.get_parser_for_file(filename)
	local ext = M.get_ext(filename)
	if not ext then
		return nil
	end
	return config.parser_map[ext]
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

--- Create replacement map for newline and tab.
---@return {[string]: string}
function M.get_replace_pair()
	return {
		["\n"] = config.marks.lf,
		["\t"] = config.marks.tab,
	}
end

function M.has_marks(line, marks)
	for _, mark in ipairs(marks) do
		if line:find(mark, 1, true) then -- true = plain search
			return true
		end
	end
	return false
end

function M.has_pipe(line)
	return M.has_marks(line, { config.marks.pipe })
end

return M
