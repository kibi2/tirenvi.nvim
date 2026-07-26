local config = require("tirenvi.config") -- Root

local Cell = require("tirenvi.core.cell") -- Core

local util = require("tirenvi.util.util") -- Util
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param line string
---@return string
local function remove_start_pipe(line)
	local pipen = config.marks.pipe
	local pipec = config.marks.pipec
	if util.start_with(line, pipen) then
		line = line:sub(#pipen + 1)
	elseif util.start_with(line, pipec) then
		line = line:sub(#pipec + 1)
	end
	return line
end

---@param line string
---@return string
local function remove_end_pipe(line)
	local pipen = config.marks.pipe
	local pipec = config.marks.pipec
	if util.end_with(line, pipen) then
		line = line:sub(1, -#pipen - 1)
	elseif util.end_with(line, pipec) then
		line = line:sub(1, -#pipec - 1)
	end
	return line
end

--#endregion
-- =============================================================================
-- Public API

---@param line string
---@return integer[]
function M.get_pipe_byte_positions(line)
	local indexes = {}
	local index = 1
	local pipe = M.get_pipe_char(line)
	if not pipe then
		return indexes
	end
	while index <= #line do
		if line:sub(index, index + #pipe - 1) == pipe then
			indexes[#indexes + 1] = index
			index = index + #pipe
		else
			index = index + 1
		end
	end
	return indexes
end

---@param byte_pos integer[]
---@param col_byte integer
---@return integer
function M.get_current_col_index(byte_pos, col_byte)
	for index, ibyte in ipairs(byte_pos) do
		if col_byte < ibyte then
			return index - 1
		end
	end
	return #byte_pos
end

---@param line string
---@return string[]
function M.get_cells(line)
	local pipen = config.marks.pipe
	local pipec = config.marks.pipec
	line = remove_start_pipe(line)
	line = remove_end_pipe(line)
	line = line:gsub(vim.pesc(pipec), pipen)
	return vim.split(line, pipen, { plain = true })
end

---@param line string
---@param pipe string
---@return boolean
function M.is_normal_grid(line, pipe)
	if not util.start_with(line, pipe) then
		return false
	end
	if not util.end_with(line, pipe) then
		return false
	end
	return true
end

---@param line string
---@return integer[]
function M.get_widths(line)
	return M.get_max_widths(line, true)
end

---@param line string
---@param no_wrap boolean|nil
---@return integer[]
function M.get_max_widths(line, no_wrap)
	local cells = M.get_cells(line)
	local widths = Cell.get_max_widths(cells, no_wrap)
	return widths
end

---@param line string|nil
---@return string|nil
function M.get_pipe_char(line)
	local pipen = config.marks.pipe
	local pipec = config.marks.pipec
	if not line then
		return nil
	end
	if line:find(pipen, 1, true) then
		return pipen
	end
	if line:find(pipec, 1, true) then
		return pipec
	end
	return nil
end

---@param lines string[]
---@return boolean
function M.has_pipe(lines)
	for _, line in ipairs(lines) do
		if M.get_pipe_char(line) then
			return true
		end
	end
	return false
end

---@param line string|nil
---@return boolean
function M.is_continue_line(line)
	local pipec = config.marks.pipec
	if not line then
		return false
	end
	return M.get_pipe_char(line) == pipec
end

---@param line string
---@param embedded_key string|nil
---@return string
---@return string
function M.split_prefix(line, embedded_key)
	if not embedded_key then
		return "", line
	end
	local byte_pos = M.get_pipe_byte_positions(line)
	if #byte_pos == 0 or byte_pos[1] == 1 then
		return "", line
	end
	local prefix = string.sub(line, 1, byte_pos[1] - 1)
	if vim.trim(prefix) ~= embedded_key then
		return "", line
	end
	return prefix, string.sub(line, byte_pos[1])
end

return M
