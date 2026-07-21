local bo = vim.bo                               -- Neovim

local common = require("tirenvi.app.common")    -- App

local Parser = require("tirenvi.parser.parser") -- Parser

local buffer = require("tirenvi.io.buffer")     -- IO
local buf_state = require("tirenvi.io.buf_state")
local attr_store = require("tirenvi.io.attr_store")

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

---@param ctx Context
function M.on_filetype(ctx)
    local old_filetype = buffer.get(ctx.bufnr, buffer.IKEY.FILETYPE)
    local new_filetype = bo[ctx.bufnr].filetype
    -- log.debug("filetype %s -> %s", tostring(old_filetype), tostring(new_filetype))
    if old_filetype and old_filetype == new_filetype then
        return
    end
    if old_filetype then
        common.to_flat(ctx)
    end
    buffer.set(ctx.bufnr, buffer.IKEY.FILETYPE, new_filetype)
    buf_state.set_buffer_tirbuf(ctx.bufnr, false)
    attr_store.write(ctx, nil)
    local parser = Parser.resolve_parser(new_filetype)
    buffer.set(ctx.bufnr, buffer.IKEY.PARSER, parser)
end

return M
