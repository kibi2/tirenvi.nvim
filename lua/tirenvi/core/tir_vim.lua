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
function M.get_pipe_indexes(line)
    local indexes = {}
    for ichar = 1, #line do
        if line:sub(ichar, ichar + plen - 1) == pipe then
            table.insert(indexes, ichar)
        end
    end
    return indexes
end

---@param count integer
---@return Range|nil
function M.get_block_range(count)
end

---@param line string
---@return boolean
function M.start_with_pipe(line)
    return line:sub(1, plen) == pipe
end

---@param line string
---@return boolean
function M.end_with_pipe(line)
    return line:sub(-plen) == pipe
end

---@param line string
---@return string
function M.remove_start_pipe(line)
    if M.start_with_pipe(line) then
        line = line:sub(plen + 1)
    end
    return line
end

---@param line string
---@return string
function M.remove_end_pipe(line)
    if M.end_with_pipe(line) then
        line = line:sub(1, -plen - 1)
    end
    return line
end

---@param line string
---@return string[]
function M.get_cells(line)
    line = M.remove_start_pipe(line)
    line = M.remove_end_pipe(line)
    return vim.split(line, pipe, { plain = true })
end

---@param line string
---@return boolean
function M.has_pipe(line)
    return line:find(config.marks.pipe, 1, true) ~= nil
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
