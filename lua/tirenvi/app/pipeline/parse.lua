local common = require("tirenvi.app.pipeline.common") -- App
local Request = require("tirenvi.app.request")
local ReadResult = require("tirenvi.app.read_result")

local Bufline = require("tirenvi.parser.bufline") -- Parser
local flat_parser = require("tirenvi.parser.flat_parser")
local Parser = require("tirenvi.parser.parser")

local buffer = require("tirenvi.io.buffer") -- IO
local buf_state = require("tirenvi.io.buf_state")
local writer = require("tirenvi.io.writer")
local reader = require("tirenvi.io.reader")

local Document = require("tirenvi.core.document") -- Core
local Attrs = require("tirenvi.core.attrs")

local util = require("tirenvi.util.util") -- Util
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param ctx Context
---@param r_result ReadResult
---@return Document
local function fltlines_to_tirdoc(ctx, r_result)
    local tirdoc = flat_parser.parse(ctx, r_result)
    log.watch("ATTR", Document.debug_attrs(tirdoc, "[1]DOC ATTR:"))
    Document.apply_attrs(tirdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(tirdoc, "[4]CACHED:"))
    return tirdoc
end

---@param ctx Context
local function embedded_on(ctx)
    if ctx.parser then
        return
    end
    ctx.parser = Parser.resolve_parser("*")
    buffer.set(ctx.bufnr, buffer.IKEY.PARSER, ctx.parser)
end

---@param ctx Context
local function embedded_off(ctx)
    buffer.set(ctx.bufnr, buffer.IKEY.PARSER, nil)
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@return nil
function M.read_post(ctx)
    local r_result = reader.read(ctx, Range.WHOLE)
    if not Bufline.has_pipe(r_result.lines) then
        util.ensure_no_reserved_marks(r_result.lines)
        local tirdoc = fltlines_to_tirdoc(ctx, r_result)
        common.doc_to_buflines(ctx, r_result, tirdoc, { no_undo = true })
    else
        local bufdoc = common.buflines_to_bufdoc_text_driven(ctx, r_result)
        common.doc_to_buflines(ctx, r_result, bufdoc, { no_undo = true })
    end
end

local backup_buffer
local backup_cursor
---@param ctx Context
function M.write_pre(ctx)
    local r_result = M.to_flat(ctx, true)
    backup_buffer = r_result.lines
    backup_cursor = r_result.cursor
    backup_cursor.restore_mode = "buffer"
end

---@param ctx Context
function M.write_post(ctx)
    if backup_buffer then
        local r_result = reader.read(ctx, Range.WHOLE)
        r_result.cursor = backup_cursor
        local req = Request.new_writer(r_result, backup_buffer, true)
        writer.write(ctx, req)
        backup_buffer = nil
        backup_cursor = nil
    end
end

---@param ctx Context
---@param filename string
function M.debug_read_tir(ctx, filename)
    local r_result = ReadResult.new_reader(Range.WHOLE)
    local jslines = vim.fn.readfile(filename)
    local tirdoc = flat_parser.from_jslines(ctx, jslines)
    common.doc_to_buflines(ctx, r_result, tirdoc)
end

---@param ctx Context
---@param filename string
function M.debug_write_tir(ctx, filename)
    local r_result = reader.read(ctx, Range.WHOLE)
    local bufdoc = common.buflines_to_bufdoc_text_driven(ctx, r_result)
    local tirdoc = Document.from_bufdoc(bufdoc)
    local jslines = flat_parser.to_jslines(tirdoc)
    vim.fn.writefile(jslines, filename)
end

---@param ctx Context
function M.from_flat(ctx)
    local r_result = reader.read(ctx, Range.WHOLE)
    util.ensure_no_reserved_marks(r_result.lines)
    local tirdoc = fltlines_to_tirdoc(ctx, r_result)
    common.doc_to_buflines(ctx, r_result, tirdoc)
end

---@param ctx Context
---@param is_write_pre boolean|nil
---@return ReadResult
function M.to_flat(ctx, is_write_pre)
    return common.to_flat(ctx, is_write_pre)
end

---@param ctx Context
function M.toggle(ctx)
    embedded_on(ctx)
    local is_flat = not buf_state.is_tirbuf(ctx.bufnr)
    if is_flat then
        M.from_flat(ctx)
        if not buf_state.has_grid(ctx) then
            embedded_off(ctx)
        end
    elseif buf_state.has_grid(ctx) then
        M.to_flat(ctx)
    end
end

return M
