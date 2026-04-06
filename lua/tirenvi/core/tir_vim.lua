local config = require("tirenvi.config")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local pipen = config.marks.pipe
local pipec = config.marks.pipec

local M = {}

-- private helpers

-- local function str_byteindex(line, char_index)
--     -- local char_index = vim.str_utfindex(str, byte_index)
--     -- vim.fn.strcharpart(str, start, len)
--     return vim.str_byteindex(line, char_index)
-- end

---@param line string
---@return string
local function remove_start_pipe(line)
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
    if util.end_with(line, pipen) then
        line = line:sub(1, - #pipen - 1)
    elseif util.end_with(line, pipec) then
        line = line:sub(1, - #pipec - 1)
    end
    return line
end

---@param base_pipe boolean
---@param target string
---@return boolean
local function same_block(base_pipe, target)
    return base_pipe == (M.has_pipe(target) ~= nil)
end

---@param lines string[]
---@param irow integer
---@param step integer  -- -1 or 1
---@return integer
local function find_block_edge(lines, irow, step)
    local base = lines[irow]
    local base_pipe = (M.has_pipe(base) ~= nil)
    local index = irow + step
    while index >= 1 and index <= #lines do
        if not same_block(base_pipe, lines[index]) then
            return index - step
        end
        index = index + step
    end
    return (step == -1) and 1 or #lines
end

---@param line string
---@param pipe string
---@return integer[]
local function get_pipe_byte_position(line, pipe)
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

-- public API

-----@param line string
-----@return integer[]
-- function M.get_cell_indexes(line)
--     local ndexes = {}
--     for ichar = 1, #line do
--         if line:sub(ichar, ichar + plen - 1) == pipe then
--             table.insert(ndexes, ichar)
--         end
--     end
--     return {}
-- end

---@param line string
---@return integer[]
function M.get_pipe_byte_position(line)
    local indexes = get_pipe_byte_position(line, pipen)
    if #indexes == 0 then
        indexes = get_pipe_byte_position(line, pipec)
    end
    return indexes
end

-----@param line string
-----@return integer[]
--function M.get_pipe_positions(line)
--    local indexes = M.get_pipe_indexes(line)
--    local positions = {}
--    for _, index in ipairs(indexes) do
--        positions[#positions + 1] = vim.str_utfindex(line, index - 1) + 1
--    end
--    return positions
--end

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

---@param lines string[]
---@param irow integer
---@return integer
function M.get_block_top_nrow(lines, irow)
    return find_block_edge(lines, irow, -1)
end

---@param lines string[]
---@param irow integer
---@return integer
function M.get_block_bottom_nrow(lines, irow)
    return find_block_edge(lines, irow, 1)
end

---@param line string
---@return string[]
function M.get_cells(line)
    line = remove_start_pipe(line)
    line = remove_end_pipe(line)
    line = line:gsub(vim.pesc(pipec), pipen)
    return vim.split(line, pipen, { plain = true })
end

---@param line string
---@return string|nil
function M.has_pipe(line)
    if line:find(pipen, 1, true) then
        return pipen
    end
    if line:find(pipec, 1, true) then
        return pipec
    end
    return nil
end

---@param line string|nil
---@return boolean
function M.is_continue_line(line)
    if not line then
        return false
    end
    return M.has_pipe(line) == pipec
end

---@param lines string[]
---@param count integer
---@param is_around boolean
---@param allow_plain boolean
---@return Rect|nil
function M.get_block_rect(lines, count, is_around, allow_plain)
    -- local mode = vim.fn.mode()
    local irow, icol0 = unpack(vim.api.nvim_win_get_cursor(0))
    local icol = icol0 + 1
    local cline = vim.api.nvim_get_current_line()
    local cbyte_pos = M.get_pipe_byte_position(cline)
    if #cbyte_pos == 0 then
        return nil
    end
    local colIndex = M.get_current_col_index(cbyte_pos, icol)
    if not colIndex then
        return nil
    end
    local trow
    local brow
    if allow_plain then
        trow = M.get_block_top_nrow(lines, irow)
        brow = M.get_block_bottom_nrow(lines, irow)
    else
        trow = 1
        brow = #lines
    end
    local tbyte_pos = M.get_pipe_byte_position(lines[trow])
    local bbyte_pos = M.get_pipe_byte_position(lines[brow])
    local end_index = colIndex + count
    end_index = math.min(end_index, #bbyte_pos)
    return {
        start_row = trow,
        end_row   = brow,
        start_col = tbyte_pos[colIndex] + (is_around and 0 or #pipen),
        end_col   = bbyte_pos[end_index] - 1
    }
end

---@param line string
---@return boolean
function M.start_with_pipe(line)
    return util.start_with(line, pipen) or util.start_with(line, pipec)
end

return M
