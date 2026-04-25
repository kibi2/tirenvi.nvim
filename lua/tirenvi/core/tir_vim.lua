local Context = require("tirenvi.app.context")
local config = require("tirenvi.config")
local util = require("tirenvi.util.util")
local buffer = require("tirenvi.io.buffer")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

local pipen = config.marks.pipe
local pipec = config.marks.pipec

local M = {}

local api = vim.api
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

---@param context Context
---@param line_provider LineProvider
---@param irow integer
---@return integer
function M.get_block_top_nrow(context, line_provider, irow, allow_plain)
    if Context.is_allow_plain(context) then
        return find_block_edge(line_provider, irow, -1)
    else
        return 1
    end
end

---@param context Context
---@param line_provider LineProvider
---@param irow integer
---@return integer
function M.get_block_bottom_nrow(context, line_provider, irow)
    if Context.is_allow_plain(context) then
        return find_block_edge(line_provider, irow, 1)
    else
        return buffer.line_count(context.bufnr)
    end
end

---@param line string
---@return string[]
function M.get_cells(line)
    line = remove_start_pipe(line)
    line = remove_end_pipe(line)
    line = line:gsub(vim.pesc(pipec), pipen)
    return vim.split(line, pipen, { plain = true })
end

---@param line string|nil
---@return string|nil
function M.get_pipe_char(line)
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

---@param line string|nil
---@return boolean
function M.is_continue_line(line)
    if not line then
        return false
    end
    return M.get_pipe_char(line) == pipec
end

---@param context Context
---@param line_provider LineProvider
---@param count integer
---@param is_around boolean
---@return Rect|nil
function M.get_block_rect(context, line_provider, count, is_around)
    -- local mode = vim.fn.mode()
    local irow, icol0 = unpack(api.nvim_win_get_cursor(0))
    local icol = icol0 + 1
    local cline = line_provider.get_line(irow) or ""
    local cbyte_pos = M.get_pipe_byte_position(cline)
    if #cbyte_pos == 0 then
        return nil
    end
    local colIndex = M.get_current_col_index(cbyte_pos, icol)
    if not colIndex then
        return nil
    end
    local trow = M.get_block_top_nrow(context, line_provider, irow)
    local brow = M.get_block_bottom_nrow(context, line_provider, irow)
    local tline = line_provider.get_line(trow) or ""
    local bline = line_provider.get_line(brow) or ""
    local tbyte_pos = M.get_pipe_byte_position(tline)
    local bbyte_pos = M.get_pipe_byte_position(bline)
    local end_index = colIndex + count
    end_index = math.min(end_index, #bbyte_pos)
    return {
        row = Range.new(trow, brow),
        col = Range.new(tbyte_pos[colIndex] + (is_around and 0 or #pipen),
            bbyte_pos[end_index] - 1),
    }
end

---@param line string
---@return boolean
function M.start_with_pipe(line)
    return util.start_with(line, pipen) or util.start_with(line, pipec)
end

return M
