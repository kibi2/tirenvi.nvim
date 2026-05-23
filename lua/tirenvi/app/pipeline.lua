-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local Document = require("tirenvi.core.document")
local Attrs = require("tirenvi.core.attrs")
local Blocks = require("tirenvi.core.blocks")
local Request = require("tirenvi.app.request")
local flat_parser = require("tirenvi.parser.flat_parser")
local vim_parser = require("tirenvi.parser.vim_parser")
local writer = require("tirenvi.io.writer")
local attr_store = require("tirenvi.io.attr_store")
local reader = require("tirenvi.io.reader")
local invalid = require("tirenvi.io.invalid")
local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-- private helpers

---@param ctx Context
---@param req_r Request
---@return Document
local function flat_to_doc(ctx, req_r)
    reader.read(ctx, req_r)
    log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "CHACHED ATTRS:"))
    util.ensure_no_reserved_marks(req_r.lines)
    local doc = flat_parser.parse(ctx, req_r)
    log.watch("ATTR", Document.debug_attrs(doc, "1DOC ATTR:"))
    Document.apply_attrs_by_id(doc, req_r.attrs)
    log.watch("ATTR", Document.debug_attrs(doc, "4CACHED:"))
    return doc
end

---@param ctx Context
---@param req_r Request
---@param range3 Range3|nil
---@return Document|nil
local function vim_to_vdoc_text_driven(ctx, req_r, range3)
    reader.read(ctx, req_r)
    if not Attrs.has_range(req_r.attrs) then
        return nil
    end
    log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "CHACHED ATTRS:"))
    req_r.attrs = Attrs.update_range(req_r.attrs or {}, range3)
    if range3 then log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "0UPDATE CHACHED:")) end
    local vim_doc = vim_parser.parse_text_driven(ctx, req_r, range3)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "1DOC ATTR:"))
    return vim_doc
end

---@param ctx Context
---@param req_r Request
---@return Document|nil
local function vim_to_vdoc_attr_driven(ctx, req_r)
    reader.read(ctx, req_r)
    if not Attrs.has_range(req_r.attrs) then
        return nil
    end
    log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "CHACHED ATTRS:"))
    local vim_doc = vim_parser.parse_attr_driven(ctx, req_r)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "1DOC ATTR:"))
    return vim_doc
end

---@param ctx Context
---@param req_r Request
---@return Document|nil
local function vim_to_doc_text_driven(ctx, req_r)
    local vim_doc = vim_to_vdoc_text_driven(ctx, req_r)
    if not vim_doc then
        return nil
    end
    Document.apply_cached_attr(vim_doc, req_r.attrs)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "4CACHED:"))
    return Document.from_vim_doc(vim_doc)
end

---@param ctx Context
---@param req_r Request
---@param no_normalize boolean -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document|nil
local function vim_to_doc_attrs_driven(ctx, req_r, no_normalize)
    local vim_doc = vim_to_vdoc_attr_driven(ctx, req_r)
    if not vim_doc or not Blocks.has_grid(vim_doc.blocks) then
        return nil
    end
    Document.insert_empty_lines(vim_doc)
    local doc = Document.from_vim_doc(vim_doc, no_normalize)
    log.watch("ATTR", Document.debug_attrs(doc, "7INSERT EMPTY:"))
    return doc
end

---@param ctx Context
---@param req_r Request
---@param vim_doc Document
---@param no_undo boolean|nil
local function doc_to_vim(ctx, req_r, vim_doc, no_undo)
    local vi_lines = vim_parser.unparse(vim_doc, req_r)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "9DOC ATTR:"))
    local req_w = Request.from_lines(req_r.range, vi_lines, no_undo or false)
    req_w.attrs = Document.replace_attrs(vim_doc, req_r.range, req_r.attrs)
    log.watch("ATTR", Attrs.debug_attrs(req_w.attrs, "9CHACHED:"))
    attr_store.write(ctx, req_w.attrs)
    if not util.same_str_array(vi_lines, req_r.lines) then
        writer.write(ctx, req_w)
    end
end

---@param ctx Context
---@param doc Document
---@param no_undo boolean|nil
local function doc_to_flat(ctx, req_r, doc, no_undo)
    local fl_lines = flat_parser.unparse(ctx, doc)
    local req_w = Request.from_lines(req_r.range, fl_lines, no_undo or false)
    req_w.attrs = vim.deepcopy(req_r.attrs)
    Attrs.remove_range(req_w.attrs)
    log.watch("ATTR", Attrs.debug_attrs(req_w.attrs, "9CHACHED:"))
    attr_store.write(ctx, req_w.attrs)
    writer.write(ctx, req_w)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param no_undo boolean|nil
---@return nil
function M.from_flat(ctx, no_undo)
    local req_r = Request.from_range(Range.WHOLE)
    local flat_doc = flat_to_doc(ctx, req_r)
    Document.set_auto_attr(flat_doc)
    log.watch("ATTR", Document.debug_attrs(flat_doc, "5AUTO ATTR:"))
    local vim_doc = Document.to_vim(flat_doc)
    doc_to_vim(ctx, req_r, vim_doc, no_undo)
end

---@param ctx Context
---@param no_undo boolean|nil
function M.to_flat(ctx, no_undo)
    local req_r = Request.from_range(Range.WHOLE)
    local doc = vim_to_doc_text_driven(ctx, req_r)
    if doc and Blocks.has_grid(doc.blocks) then
        doc_to_flat(ctx, req_r, doc, no_undo)
    end
end

---@param ctx Context
---@param sel Rect
---@param width_op WidthOp
function M.cmd_width(ctx, sel, width_op)
    invalid.clear(ctx.bufnr)
    log.debug("row%s, col%s", Range.short(sel.row), Range.short(sel.col))
    local req_r = Request.from_range(sel.row)
    local doc = vim_to_doc_text_driven(ctx, req_r)
    if doc and Blocks.has_grid(doc.blocks) then
        Blocks.change_width(doc.blocks, sel.col, width_op)
        local vim_doc = Document.to_vim(doc)
        doc_to_vim(ctx, req_r, vim_doc)
    end
end

---@param ctx Context
---@param no_normalize boolean|nil
---@param no_undo boolean|nil
function M.cmd_format(ctx, no_normalize, no_undo)
    invalid.clear(ctx.bufnr)
    no_normalize = no_normalize or false
    local req_r = Request.from_range(Range.WHOLE)
    local doc = vim_to_doc_attrs_driven(ctx, req_r, no_normalize)
    if not doc or not Blocks.has_grid(doc.blocks) then
        return
    end
    local vim_doc = Document.to_vim(doc)
    doc_to_vim(ctx, req_r, vim_doc, no_undo)
end

---@param ctx Context
---@param range3 Range3
function M.update_attrs(ctx, range3)
    local req_r = Request.from_range(Range3.get_new_range(range3))
    local vim_doc = vim_to_vdoc_text_driven(ctx, req_r, range3)
    if not vim_doc then
        return nil
    end
    Document.inherit_neighbor_attr(vim_doc, req_r.attrs, range3)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "2NEIGHBOR:"))
    Document.infer_consistent_attr(vim_doc)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "3CONSISTENT:"))
    Document.apply_cached_attr(vim_doc, req_r.attrs)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "4CACHED:"))
    Document.set_auto_attr(vim_doc)
    log.watch("ATTR", Document.debug_attrs(vim_doc, "5AUTO ATTR:"))
    local attrs = Document.replace_attrs(vim_doc, req_r.range, req_r.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "6RESULT:"))
    attr_store.write(ctx, attrs)
end

return M
