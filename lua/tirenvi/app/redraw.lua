local api = vim.api                                     -- Neovim

local common = require("tirenvi.app.common")            -- App

local buf_parser = require("tirenvi.parser.buf_parser") -- Parse

local buf_state = require("tirenvi.io.buf_state")       -- IO
local reader = require("tirenvi.io.reader")
local dirty = require("tirenvi.io.dirty")

local Document = require("tirenvi.core.document") -- Core
local Attrs = require("tirenvi.core.attrs")

local Range = require("tirenvi.util.range") -- Util
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param ctx Context
---@param r_result ReadResult
-- Prevents line count changes that would break put(); used for repair.
---@return Document
local function buflines_to_bufdoc_attrs_driven(ctx, r_result)
    log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "CHACHED ATTRS:"))
    local opts = { attrs = r_result.attrs }
    local bufdoc = buf_parser.parse(ctx, r_result, opts)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    Document.insert_empty_lines(bufdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[7]INSERT EMPTY:"))
    return bufdoc
end

local schedule_repair_flag = false
---@param ctx Context
---@param range3 Range3|nil
local function schedule_repair(ctx, range3)
    if not schedule_repair_flag then
        vim.schedule(function()
            schedule_repair_flag = false
            local no_normalize = range3 and Range3.get_delta(range3) == 0 or false
            M.cmd_redraw(ctx, { no_undo = true, no_normalize = no_normalize })
        end)
        schedule_repair_flag = true
    else
        local dirty_ranges = dirty.get_ranges(ctx.bufnr)
        log.watch("UNDO", ctx.bufnr, { "multi time on_lines", dirty_ranges })
    end
end

---@param ctx Context
---@param range3 Range3|nil
local function repair_request(ctx, range3)
    if buf_state.is_repair(ctx, range3) then
        schedule_repair(ctx, range3)
    end
end

---@param ctx Context
---@return boolean
local function need_repair(ctx)
    if not buf_state.is_tirbuf(ctx.bufnr) then
        return false
    end
    if not buf_state.has_grid(ctx.bufnr) then
        return false
    end
    -- repair must remove redundant padding,
    -- so it does not check whether dirty exists.
    return true
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@param opts DocToBufLinesOpts|nil
function M.cmd_redraw(ctx, opts)
    if not need_repair(ctx) then
        return
    end
    log.debug("===+=== START ===+=== %s[#%d] ===", "REPAIR", ctx.bufnr)
    local r_result = reader.read(ctx, Range.WHOLE)
    log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "[88]MODE:"))
    local bufdoc = buflines_to_bufdoc_attrs_driven(ctx, r_result)
    common.doc_to_buflines(ctx, r_result, bufdoc, opts)
end

---@param ctx Context
---@param range3 Range3|nil
function M.check_and_repair(ctx, range3)
    local bufnr = ctx.bufnr
    vim.schedule(function()
        if not api.nvim_buf_is_valid(bufnr) then
            return
        end
        if api.nvim_get_current_buf() ~= bufnr then
            return
        end
        local ok, err = xpcall(
            function()
                repair_request(ctx, range3)
            end,
            debug.traceback
        )
        if not ok then
            error(err)
        end
    end)
end

return M
