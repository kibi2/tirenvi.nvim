local config = require("tirenvi.config")
local range = require("tirenvi.util.range")
local render = require("tirenvi.render")

local matches = {}

local M = {}

-- =========================
-- setup
-- =========================

function M.setup()
    M.special_setup()
    M.table_setup()
    M.diagnostic_setup()
end

-- =========================
-- utils
-- =========================

---@param name string
---@param targets string[]
local function safe_link_multi(name, targets)
    for _, t in ipairs(targets) do
        local ok = pcall(vim.api.nvim_get_hl, 0, { name = t })
        if ok then
            vim.api.nvim_set_hl(0, name, { link = t })
            return
        end
    end
end

-- =========================
-- special chars
-- =========================

function M.special_setup()
    vim.api.nvim_set_hl(0, "TirenviPadding", { fg = "bg", bg = "bg", })
    safe_link_multi("TirenviPipe", { "@punctuation.special.markdown", "Delimiter", "Special", })
    safe_link_multi("TirenviSpecialChar", { "NonText", })
end

---@param winid integer
---@param group string
---@param pattern string
---@param priority integer
local function add_match(winid, group, pattern, priority)
    local id = vim.fn.matchadd(group, "\\V" .. pattern, priority)
    matches[winid] = matches[winid] or {}
    table.insert(matches[winid], id)
end

---@param winid integer
function M.clear_matches(winid)
    local ids = matches[winid]
    if not ids then return end
    for _, id in ipairs(ids) do
        pcall(vim.fn.matchdelete, id)
    end
    matches[winid] = nil
end

function M.special_apply()
    local winid = vim.api.nvim_get_current_win()
    M.clear_matches(winid)
    add_match(winid, "TirenviPipe", config.marks.pipe, 20)
    add_match(winid, "TirenviSpecialChar", config.marks.lf, 20)
    add_match(winid, "TirenviSpecialChar", config.marks.tab, 20)
    add_match(winid, "TirenviPadding", config.marks.padding, 10)
end

function M.special_clear()
    local winid = vim.api.nvim_get_current_win()
    M.clear_matches(winid)
end

-- =========================
-- table
-- =========================

function M.table_setup()
    local title = vim.api.nvim_get_hl(0, { name = "Title" })
    vim.api.nvim_set_hl(0, "TirenviHeader", {
        fg = title.fg,
        bg = title.bg,
        bold = title.bold,
        underline = true,
        sp = title.fg,
    })
end

---@param bufnr number
---@param i_start integer
---@param lines string[]
local function highlight(bufnr, i_start, lines)
    local has_pipe = false
    for index, line in ipairs(lines) do
        if line:find(config.marks.pipe, 1, true) ~= nil then
            if has_pipe == false then
                render.highlight_header_line(bufnr, index + i_start - 1, line)
            end
            has_pipe = true
        else
            has_pipe = false
        end
    end
end

---@param bufnr number
---@param i_start integer
---@param lines string[]
function M.table_apply_header(bufnr, i_start, lines)
    highlight(bufnr, i_start, lines)
end

-- =========================
-- diagnostic
-- =========================

function M.diagnostic_setup()
    vim.fn.sign_define("TirenviSign", { text = "◆", texthl = "ErrorMsg" })
    vim.api.nvim_set_hl(0, "TirenviDebugLine", { bg = "#888840" })
end

---@param bufnr number
---@param ranges Range[]
function M.diagnostic_set(bufnr, ranges)
    for index, range in ipairs(ranges) do
        render.set_range(bufnr, range.first, range.last, index)
    end
end

---@param bufnr number
---@param first integer | nil
---@param last integer | nil
---@return Range[]
function M.diagnostic_get(bufnr, first, last)
    local ranges = render.get_range(bufnr)
    if first then
        ---@cast last integer
        ranges[#ranges + 1] = { first = first, last = last - 1 }
    end
    return range.union(ranges)
end

---@param bufnr number
function M.diagnostic_clear(bufnr)
    render.clear(bufnr)
end

return M
