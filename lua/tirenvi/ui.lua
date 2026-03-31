local config = require("tirenvi.config")
local range = require("tirenvi.util.range")
local render = require("tirenvi.render")
local buffer = require("tirenvi.state.buffer")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local matches = {}

local M = {}

-- =========================
-- setup
-- =========================

function M.setup()
    M.special_setup()
    M.diagnostic_setup()
end

-- =========================
-- utils
-- =========================

---@param targets string[]
---@return string
local function get_safe_link_name(targets)
    for _, target in ipairs(targets) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = target })
        if ok and hl and next(hl) ~= nil then
            return target
        end
    end
    return "Normal"
end

---@param name string
---@param targets string[]
local function safe_link_multi(name, targets)
    local target = get_safe_link_name(targets)
    vim.api.nvim_set_hl(0, name, { link = target })
end

---@param bufnr number
---@param i_start integer
---@param i_end integer integer
---@param lines string[]
---@param strict boolean|nil
---@param no_undo boolean|nil
function M.set_lines(bufnr, i_start, i_end, lines, strict, no_undo)
    buffer.set_lines(bufnr, i_start, i_end, lines, strict, no_undo)
end

-- =========================
-- special chars
-- =========================

function M.special_setup()
    vim.api.nvim_set_hl(0, "TirenviPadding", {})
    local target = get_safe_link_name({ "@punctuation.special.markdown", "Delimiter", "Special", })
    local special = vim.api.nvim_get_hl(0, { name = target })
    vim.api.nvim_set_hl(0, "TirenviPipeNoHbar", { link = target })
    vim.api.nvim_set_hl(0, "TirenviPipe", {
        fg = special.fg,
        bg = special.bg,
        underline = true,
    })
    vim.api.nvim_set_hl(0, "TirenviHbar", {
        underline = true,
        sp = special.fg,
    })
    safe_link_multi("TirenviSpecialChar", { "NonText", })
end

---@param winid integer
---@param group string
---@param pattern string
---@param priority integer
local function add_match(winid, group, pattern, priority)
    local id = vim.fn.matchadd(group, pattern, priority)
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

local function pat_v(s)
    return "\\V" .. s
end

local function pat_line_inner(pipe)
    return "^" .. pipe .. "\\zs.*\\ze" .. pipe .. "$"
end

local function pat_line_start(pipe)
    return "^" .. pipe
end

local function pat_line_end(pipe)
    return pipe .. "$"
end

function M.special_apply()
    local winid = vim.api.nvim_get_current_win()
    M.clear_matches(winid)
    add_match(winid, "TirenviPadding", pat_v(config.marks.padding), 10)
    add_match(winid, "TirenviSpecialChar", pat_v(config.marks.lf), 20)
    add_match(winid, "TirenviSpecialChar", pat_v(config.marks.tab), 20)
    local pipe = config.marks.pipe
    if vim.w.tirenvi_view_bar then
        add_match(winid, "TirenviPipe", pat_v(pipe), 30)
        add_match(winid, "TirenviHbar", pat_line_inner(pipe), 20)
        add_match(winid, "TirenviPipeNoHbar", pat_line_start(pipe), 40)
        add_match(winid, "TirenviPipeNoHbar", pat_line_end(pipe), 40)
    else
        add_match(winid, "TirenviPipeNoHbar", pat_v(pipe), 30)
    end
end

function M.special_clear()
    local winid = vim.api.nvim_get_current_win()
    M.clear_matches(winid)
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
---@param first integer|nil
---@param last integer|nil
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
