local config = require("tirenvi.config")
local log = require("tirenvi.util.log")

local pipe = config.marks.pipe
local plen = #pipe

local M = {}

-- private helpers

-- local function str_byteindex(line, char_index)
--     -- local char_index = vim.str_utfindex(str, byte_index)
--     -- vim.fn.strcharpart(str, start, len)
--     return vim.str_byteindex(line, char_index)
-- end

---@param line string
---@return boolean
local function start_with_pipe(line)
    return line:sub(1, plen) == pipe
end

---@param line string
---@return boolean
local function end_with_pipe(line)
    return line:sub(-plen) == pipe
end

---@param line string
---@return string
local function remove_start_pipe(line)
    if start_with_pipe(line) then
        line = line:sub(plen + 1)
    end
    return line
end

---@param line string
---@return string
local function remove_end_pipe(line)
    if end_with_pipe(line) then
        line = line:sub(1, -plen - 1)
    end
    return line
end

---@param base_pipe boolean
---@param target string
---@return boolean
local function same_block(base_pipe, target)
    return base_pipe == M.has_pipe(target)
end

---@param lines string[]
---@param irow integer
---@param step integer  -- -1 or 1
---@return integer
local function find_block_edge(lines, irow, step)
    local base = lines[irow]
    local base_pipe = M.has_pipe(base)
    local index = irow + step
    while index >= 1 and index <= #lines do
        if not same_block(base_pipe, lines[index]) then
            return index - step
        end
        index = index + step
    end
    return (step == -1) and 1 or #lines
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
local function get_pipe_byte_position(line)
    local indexes = {}
    local index = 1
    while index <= #line do
        if line:sub(index, index + plen - 1) == pipe then
            indexes[#indexes + 1] = index
            index = index + plen
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
    return vim.split(line, pipe, { plain = true })
end

---@param line string
---@return boolean
function M.has_pipe(line)
    return line:find(pipe, 1, true) ~= nil
end

---@param lines string[]
---@param count integer
---@param is_around boolean
---@param allow_plain boolean
---@return Range|nil
function M.get_block_range(lines, count, is_around, allow_plain)
    -- local mode = vim.fn.mode()
    local irow, icol0 = unpack(vim.api.nvim_win_get_cursor(0))
    local icol = icol0 + 1
    local cline = vim.api.nvim_get_current_line()
    local cbyte_pos = get_pipe_byte_position(cline)
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
    local tbyte_pos = get_pipe_byte_position(lines[trow])
    local bbyte_pos = get_pipe_byte_position(lines[brow])
    return {
        start_row = trow,
        end_row   = brow,
        start_col = tbyte_pos[colIndex] + (is_around and 0 or plen),
        end_col   = bbyte_pos[colIndex + 1] - 1
    }
end

return M
