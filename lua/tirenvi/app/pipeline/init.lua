-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
function M.read_post(ctx)
    require("tirenvi.app.pipeline.parse").read_post(ctx)
end

---@param ctx Context
function M.write_pre(ctx)
    require("tirenvi.app.pipeline.parse").write_pre(ctx)
end

---@param ctx Context
function M.write_post(ctx)
    require("tirenvi.app.pipeline.parse").write_post(ctx)
end

---@param ctx Context
---@param filename string
function M.debug_read_tir(ctx, filename)
    require("tirenvi.app.pipeline.parse").debug_read_tir(ctx, filename)
end

---@param ctx Context
---@param filename string
function M.debug_write_tir(ctx, filename)
    require("tirenvi.app.pipeline.parse").debug_write_tir(ctx, filename)
end

---@param ctx Context
function M.from_flat(ctx)
    require("tirenvi.app.pipeline.parse").from_flat(ctx)
end

---@param ctx Context
---@param is_write_pre boolean|nil
---@return ReadResult
function M.to_flat(ctx, is_write_pre)
    return require("tirenvi.app.pipeline.parse").to_flat(ctx, is_write_pre)
end

---@param ctx Context
function M.toggle(ctx)
    return require("tirenvi.app.pipeline.parse").toggle(ctx)
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_width(ctx, width_op)
    require("tirenvi.app.pipeline.width").cmd_width(ctx, width_op)
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_fit(ctx, width_op)
    require("tirenvi.app.pipeline.width").cmd_fit(ctx, width_op)
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_wrap(ctx, width_op)
    require("tirenvi.app.pipeline.width").cmd_wrap(ctx, width_op)
    M.cmd_redraw(ctx)
end

---@param ctx Context
---@param opts DocToBufLinesOpts|nil
function M.cmd_redraw(ctx, opts)
    require("tirenvi.app.pipeline.redraw").cmd_redraw(ctx, opts)
end

---@param ctx Context
---@param range3 Range3|nil
function M.check_and_repair(ctx, range3)
    require("tirenvi.app.pipeline.redraw").check_and_repair(ctx, range3)
end

---@param ctx Context
---@param range3 Range3
function M.on_lines(ctx, range3)
    require("tirenvi.app.pipeline.on_lines").on_lines(ctx, range3)
end

---@param ctx Context
function M.auto_wrap(ctx)
    require("tirenvi.app.pipeline.auto_wrap").auto_wrap(ctx)
end

---@param ctx Context
function M.on_filetype(ctx)
    require("tirenvi.app.pipeline.filetype").on_filetype(ctx)
end

---@param ctx Context
function M.insert_char_in_newline(ctx)
    require("tirenvi.app.pipeline.insert").insert_char_in_newline(ctx)
end

---@return string
function M.keymap_lf()
    return require("tirenvi.app.pipeline.insert").keymap_lf()
end

---@return string
function M.keymap_tab()
    return require("tirenvi.app.pipeline.insert").keymap_tab()
end

return M
