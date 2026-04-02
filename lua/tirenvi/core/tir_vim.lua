local config = require("tirenvi.config")
local log = require("tirenvi.util.log")

local pipe = config.marks.pipe
local plen = #pipe

local M = {}

-- private helpers

local function str_byteindex(line, char_index)
    -- local char_index = vim.str_utfindex(str, byte_index)
    -- vim.fn.strcharpart(str, start, len)
    return vim.str_byteindex(line, char_index)
end

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

-- public API

---@param line string
---@return integer[]
function M.get_cell_indexes(line)
    local ndexes = {}
    log.probe(plen)
    for ichar = 1, #line do
        if line:sub(ichar, ichar + plen - 1) == pipe then
            table.insert(ndexes, ichar)
        end
    end
    return {}
end

---@param line string
---@return integer[]
function M.get_pipe_byte_indexes(line)
    local indexes = {}
    local index = 1
    while index <= #line do
        if line:sub(index, index + plen - 1) == pipe then
            indexes[#indexes] = index
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

---@param line string
---@return integer[]
function M.get_pipe_positions(line)
    local indexes = M.get_pipe_indexes(line)
    local positions = {}
    for _, index in ipairs(indexes) do
        positions[#positions] = vim.str_utfindex(line, index - 1) + 1
    end
    return positions
end

---@param indexes integer[]
---@param current_index integer
---@return integer
function M.get_current_row_index(indexes, current_index)
    for _, index in ipairs(indexes) do
        if current_index < index then
            return index - 1
        end
    end
    return #indexes
end

---@param base_pipe boolean
---@param target string
---@return boolean
local function same_block(base_pipe, target)
    return base_pipe == M.has_pipe(target)
end

---@param lines string[]
---@param current_index integer
---@param step integer  -- -1 or 1
---@return integer
local function find_block_edge(lines, current_index, step)
    local base = lines[current_index]
    local base_pipe = M.has_pipe(base)
    local index = current_index + step
    while index >= 1 and index <= #lines do
        if not same_block(base_pipe, lines[index]) then
            return index - step
        end
        index = index + step
    end
    return (step == -1) and 1 or #lines
end

---@param lines string[]
---@param current_index integer
---@return integer
function M.get_block_top_nrow(lines, current_index)
    return find_block_edge(lines, current_index, -1)
end

---@param lines string[]
---@param current_index integer
---@return integer
function M.get_block_bottom_nrow(lines, current_index)
    return find_block_edge(lines, current_index, 1)
end

---@param count integer
---@return Range|nil
function M.get_block_range(count)
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

---@param count integer
---@return Range|nil
function M.get_select(count)
    log.probe("get_select:" .. count)
    log.probe("select_column")
    local mode = vim.fn.mode()
    log.probe(mode)

    local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
    local col = col0 + 1
    local line = vim.api.nvim_get_current_line()
    log.probe({ row, col, line })

    local pipes = {}
    log.probe(plen)
    for ichar = 1, #line do
        if line:sub(ichar, ichar + plen - 1) == pipe then
            table.insert(pipes, ichar)
        end
    end
    log.probe(pipes)

    local col_idx
    for index = 1, #pipes - 1 do
        if col >= pipes[index] and col < pipes[index + 1] then
            col_idx = index
            break
        end
    end
    log.probe(col_idx)
    if not col_idx then return nil end


    return {
        start_row = 2,
        end_row   = 3,
        start_col = pipes[col_idx] + plen - 1,
        end_col   = pipes[col_idx + 1] - 2
    }
end

return M
