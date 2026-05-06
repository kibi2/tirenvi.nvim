local config  = require("tirenvi.config")
local invalid = require("tirenvi.io.invalid")
local Range   = require("tirenvi.util.range")
local log     = require("tirenvi.util.log")

local matches = {}

local M       = {}

local api     = vim.api
local fn      = vim.fn
local pipen   = config.marks.pipe
local pipec   = config.marks.pipec

-- =========================
-- utils
-- =========================

---@param targets string[]
---@return string
local function get_safe_link_name(targets)
    for _, target in ipairs(targets) do
        local ok, hl = pcall(api.nvim_get_hl, 0, { name = target })
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
    api.nvim_set_hl(0, name, { link = target })
end

local function diagnostic_setup()
    fn.sign_define("TirenviSign", { text = "◆", texthl = "ErrorMsg" })
    api.nvim_set_hl(0, "TirenviDebugLine", { bg = "#888840" })
end

local function special_setup()
    api.nvim_set_hl(0, "TirenviPadding", {})
    local target = get_safe_link_name({ "@punctuation.special.markdown", "Delimiter", "Special", })
    local special = api.nvim_get_hl(0, { name = target })
    api.nvim_set_hl(0, "TirenviPipeNoHbar", { link = target })
    api.nvim_set_hl(0, "TirenviPipeHbar", {
        fg = special.fg,
        bg = special.bg,
        underline = true,
        nocombine = true,
    })
    api.nvim_set_hl(0, "TirenviHbar", {
        underline = true,
        sp = special.fg,
        nocombine = true,
    })
    api.nvim_set_hl(0, "Conceal", { link = "TirenviPipeNoHbar" })
    safe_link_multi("TirenviSpecialChar", { "NonText", })
end

-- =========================
-- special chars
-- =========================

---@param winid integer
---@param group string
---@param pattern string
---@param priority integer
local function add_match(winid, group, pattern, priority)
    local id = fn.matchadd(group, pattern, priority)
    matches[winid] = matches[winid] or {}
    table.insert(matches[winid], id)
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

function M.setup()
    special_setup()
    diagnostic_setup()
end

---@param winid integer|nil
function M.special_clear(winid)
    winid = winid or api.nvim_get_current_win()
    local ids = matches[winid]
    if not ids then return end
    for _, id in ipairs(ids) do
        pcall(fn.matchdelete, id)
    end
    matches[winid] = nil
end

---@param winid integer|nil
function M.special_apply(winid)
    winid = winid or api.nvim_get_current_win()
    M.special_clear(winid)
    add_match(winid, "TirenviPadding", pat_v(config.marks.padding), 10)
    add_match(winid, "TirenviSpecialChar", pat_v(config.marks.lf), 20)
    add_match(winid, "TirenviSpecialChar", pat_v(config.marks.tab), 20)
    add_match(winid, "TirenviPipeHbar", pat_v(pipen), 30)
    add_match(winid, "TirenviHbar", pat_line_inner(pipen), 20)
    add_match(winid, "TirenviPipeNoHbar", pat_line_start(pipen), 40)
    add_match(winid, "TirenviPipeNoHbar", pat_line_end(pipen), 40)
    add_match(winid, "TirenviPipeNoHbar", pat_v(pipec), 30)
    vim.opt_local.conceallevel = config.ui.conceal.level
    vim.opt_local.concealcursor = config.ui.conceal.cursor
    local pattern = fn.escape(pipec, [[/\]])
    local command = string.format([[syntax match TirPipeC /%s/ conceal cchar=%s]], pattern, pipen)
    vim.cmd(command)
end

-- =========================
-- diagnostic
-- =========================

---@param bufnr number
---@param ranges Range[]
function M.diagnostic_set(bufnr, ranges)
    for index, range in ipairs(ranges) do
        local range_lua = Range.from_lua(range.first + 1, range.last)
        invalid.set_range(bufnr, range_lua, index)
    end
end

---@param bufnr number
function M.diagnostic_clear(bufnr)
    invalid.clear(bufnr)
end

api.nvim_create_autocmd("ColorScheme", {
    callback = M.setup
})

return M
