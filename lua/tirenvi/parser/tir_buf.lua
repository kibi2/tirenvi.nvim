local config = require("tirenvi.config") -- Root

local buf_state = require("tirenvi.io.buf_state") -- Cursor

local CursorNvim = require("tirenvi.cursor.nvim") -- Cursor

local Cell = require("tirenvi.core.cell") -- Core

local util = require("tirenvi.util.util") -- Util
local Range = require("tirenvi.util.range")
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

---@param base_pipe boolean
---@param target string|nil
---@return boolean
local function is_block_boundary(base_pipe, target)
	if not target then
		return true
	end
	return base_pipe ~= (M.get_pipe_char(target) ~= nil)
end

---@param provider LineProvider
---@param irow integer
---@param step integer  -- -1 or 1
---@return integer
local function find_block_edge(provider, irow, step)
	local line = provider.get_line(irow)
	local base_pipe = (M.get_pipe_char(line) ~= nil)
	while true do
		irow = irow + step
		local line = provider.get_line(irow)
		if is_block_boundary(base_pipe, line) then
			return irow - step
		end
	end
end

---@param line string
---@param pipe string
---@return integer[]
local function get_pipe_byte_positions(line, pipe)
	local indexes = {}
	local index = 1
	while index <= #line do
		if line:sub(index, index + #pipe - 1) == pipe then
			indexes[#indexes + 1] = index
			index = index + #pipe
		else
			index = index + 1
		end
	end
	if #indexes > 0 then
		if indexes[1] ~= 1 then
			table.insert(indexes, 1, 0)
		end
	end
	return indexes
end

--#endregion
-- =============================================================================
-- Public API

---@param line string
---@return integer[]
function M.get_pipe_byte_position(line)
	local pipen = config.marks.pipe
	local indexes = get_pipe_byte_positions(line, pipen)
	if #indexes == 0 then
		local pipec = config.marks.pipec
		indexes = get_pipe_byte_positions(line, pipec)
	end
	return indexes
end

---@param byte_pos integer[]
---@param icol integer
---@return integer|nil
function M.get_current_col_index(byte_pos, icol)
	for index, ibyte in ipairs(byte_pos) do
		if icol < ibyte then
			return index - 1
		end
	end
	return nil
end

---@param ctx Context
---@param line_provider LineProvider
---@param irow integer
---@return integer
function M.get_block_top_nrow(ctx, line_provider, irow)
	if buf_state.is_allow_plain(ctx.bufnr) then
		return find_block_edge(line_provider, irow, -1)
	else
		return 1
	end
end

---@param ctx Context
---@param line_provider LineProvider
---@param irow integer
---@return integer
function M.get_block_bottom_nrow(ctx, line_provider, irow)
	if buf_state.is_allow_plain(ctx.bufnr) then
		return find_block_edge(line_provider, irow, 1)
	else
		return line_provider.line_count()
	end
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

---@param ctx Context
---@param count integer
---@param is_around boolean
---@return Rect|nil
---@return string[]
function M.get_block_rect(ctx, count, is_around)
	local cursor = CursorNvim.capture(ctx)
	local row_cur = cursor.row_cur
	local col_byte = cursor.col_byte
	local cline = ctx.line_provider.get_line(row_cur) or ""
	local cbyte_pos = M.get_pipe_byte_position(cline)
	if #cbyte_pos == 0 then
		return nil, {}
	end
	local colIndex = M.get_current_col_index(cbyte_pos, col_byte)
	if not colIndex then
		return nil, {}
	end
	local trow = M.get_block_top_nrow(ctx, ctx.line_provider, row_cur)
	local brow = M.get_block_bottom_nrow(ctx, ctx.line_provider, row_cur)
	local lines = ctx.line_provider.get_lines(trow, brow)
	local tline = lines[1]
	local bline = lines[#lines]
	local tbyte_pos = M.get_pipe_byte_position(tline)
	local bbyte_pos = M.get_pipe_byte_position(bline)
	local end_index = colIndex + count
	end_index = math.min(end_index, #bbyte_pos)
	local pipe = M.get_pipe_char(tline)
	local rect = {
		row = Range.from_lua(trow, brow),
		col = Range.from_lua(
			tbyte_pos[colIndex] + (is_around and 0 or #pipe),
			bbyte_pos[end_index] - 1
		),
	}
	return rect, lines
end

---@param line string
---@return string
function M.get_prefix_part(line)
	local pipe = M.get_pipe_char(line)
	if not pipe then
		return ""
	end
	local pos_byte = string.find(line, pipe, 1, true) or 1
	return string.sub(line, 1, pos_byte - 1)
end

return M
