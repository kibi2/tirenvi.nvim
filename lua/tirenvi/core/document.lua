local CONST = require("tirenvi.constants")
local Attr = require("tirenvi.core.attr")
local Attrs = require("tirenvi.core.attrs")
local Blocks = require("tirenvi.core.blocks")
local Block = require("tirenvi.core.block")
local Range = require("tirenvi.util.range")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

---@class Document
---@field _tir boolean
---@field attr Attr_doc
---@field blocks Blocks

---@alias Blocks Block[]

---@alias Block
---| Block_plain
---| Block_grid

---@alias Block_kind
---| "plain"
---| "grid"

---@class Block_plain
---@field kind "plain"
---@field attr Attr
---@field records Record_plain[]

---@class Block_grid
---@field kind "grid"
---@field attr Attr
---@field records Record_grid[]

---@class Attr_file
---@field kind "attr_file"
---@field version string

---@class Attr_doc
---@field allow_plain boolean

---@class Attr
---@field range Range
---@field columns Attr_column[]

---@class Attr_column
---@field width integer                 display width (logical column width)
---@field fix_width integer             width for fix mode

---@alias Record Record_plain|Record_grid

---@class Record_plain
---@field kind "plain"
---@field line string

---@class Record_grid
---@field kind "grid"
---@field row Cell[]
---@field _has_continuation? boolean    true if this record continues to the next row

---@alias Cell string

---@alias Ndjson Attr_file|Record

local VERSION = "tir/0.1"

-- private helpers

---@param ndjsons Record[]
---@param allow_plain boolean
---@param attrs Attr[]|nil
---@return Document
local function new(ndjsons, allow_plain, attrs)
    local self = {}
    self.attr = { allow_plain = allow_plain }
    self.blocks = Blocks.new_from_records(ndjsons, attrs)
    return self
end

---@return Ndjson
local function new_attr_file()
    return { kind = CONST.KIND.ATTR_FILE, version = VERSION }
end

---@param self Document
---@return Attr[]
local function collect_attrs(self)
    return Blocks.collect_attrs(self.blocks)
end

---@param bufdoc Document
local function set_attr_range(bufdoc, first)
    Blocks.set_attr_range(bufdoc.blocks, first)
end

---@param bufdoc Document
---@param attrs Attr[]
local function apply_attrs_by_range(bufdoc, attrs)
    log.assert(not bufdoc._tir, "apply_attrs_by_range should be called only for bufdoc")
    Blocks.apply_attrs_by_range(bufdoc.blocks, attrs)
end

---@param tirdoc Document
---@param c_attrs Attr[]
local function apply_attrs_by_id(tirdoc, c_attrs)
    log.assert(tirdoc._tir, "apply_attrs_by_id should be called only for tirdoc")
    local attrs_grid = Attrs.get_grid_attrs(c_attrs)
    local iblock = 0
    for _, block in ipairs(tirdoc.blocks) do
        block.attr = Attr[block.kind].new()
        if block.kind == CONST.KIND.GRID then
            iblock = iblock + 1
            if attrs_grid[iblock] then
                block.attr.columns = attrs_grid[iblock].columns
            end
        end
    end
end

---@param tirdoc Document
local function to_flatdoc(tirdoc)
    log.assert(tirdoc._tir, "to_flatdoc should be called only for tirdoc")
    Blocks.to_flat(tirdoc.blocks)
    tirdoc._tir = true
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ndjsons Ndjson[]
---@param allow_plain boolean
---@return Document
function M.new_tirdoc(ndjsons, allow_plain)
    local tirdoc = new(ndjsons, allow_plain)
    Blocks.from_flat(tirdoc.blocks)
    tirdoc._tir = true
    return tirdoc
end

---@param records Record[]
---@param allow_plain boolean
---@param attrs Attr[]|nil
---@param first integer|nil
---@return Document
function M.new_bufdoc(records, allow_plain, attrs, first)
    local bufdoc = new(records, allow_plain, attrs)
    set_attr_range(bufdoc, first)
    bufdoc._tir = false
    return bufdoc
end

---@param bufdoc Document
---@param no_normalize boolean|nil  -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document
function M.from_bufdoc(bufdoc, no_normalize)
    log.assert(not bufdoc._tir, "from_bufdoc should be called only for bufdoc")
    no_normalize = no_normalize or false
    local tirdoc = vim.deepcopy(bufdoc)
    Blocks.from_buf(tirdoc.blocks, no_normalize)
    tirdoc._tir = true
    return tirdoc
end

---@param tirdoc Document
---@return Document
function M.to_bufdoc(tirdoc)
    log.assert(tirdoc._tir, "to_bufdoc should be called only for tirdoc")
    local bufdoc = vim.deepcopy(tirdoc)
    Blocks.to_bufdoc(bufdoc.blocks)
    bufdoc._tir = false
    return bufdoc
end

---@param bufdoc Document
---@return Record[]
function M.serialize_to_buf(bufdoc)
    log.assert(not bufdoc._tir, "serialize_to_buf should be called only for bufdoc")
    return Blocks.serialize(bufdoc.blocks)
end

---@param tirdoc Document
---@return Ndjson[]
function M.serialize_to_flat(tirdoc)
    log.assert(tirdoc._tir, "serialize_to_flat should be called only for tirdoc")
    to_flatdoc(tirdoc)
    local ndjsons = { new_attr_file() }
    util.extend(ndjsons, Blocks.serialize(tirdoc.blocks))
    return ndjsons
end

---@param bufdoc Document
---@param range Range
---@param chached_attrs Attr[]
---@return Attr[]
function M.replace_attrs(bufdoc, range, chached_attrs)
    log.assert(not bufdoc._tir, "replace_attrs should be called only for bufdoc")
    local first = Range.to_lua(range)
    set_attr_range(bufdoc, first)
    local doc_attrs = Blocks.collect_attrs(bufdoc.blocks)
    if not chached_attrs or Range.is_whole(range) then
        return doc_attrs
    end
    return Attrs.replace_attrs(chached_attrs, range, doc_attrs)
end

---@param bufdoc Document
function M.infer_consistent_attr(bufdoc)
    log.assert(not bufdoc._tir, "infer_consistent_attr should be called only for bufdoc")
    Blocks.infer_consistent_attr(bufdoc.blocks)
end

---@param bufdoc Document
function M.set_max_attr(bufdoc)
    --log.assert(not bufdoc._tir, "set_auto_attr should be called only for bufdoc")
    Blocks.set_max_attr(bufdoc.blocks)
    log.watch("ATTR", M.debug_attrs(bufdoc, "[5]MAX ATTR:"))
end

---@param doc Document
---@param attrs Attr[]
function M.apply_attrs(doc, attrs)
    if doc._tir then
        apply_attrs_by_id(doc, attrs)
    else
        apply_attrs_by_range(doc, attrs)
    end
end

---@param self Document
function M:debug_attrs(title)
    if not log.is_debug() then
        return
    end
    local attrs = collect_attrs(self)
    return Attrs.debug_attrs(attrs, title)
end

---@param bufdoc Document
---@param attrs Attr[]
---@param range3 Range3
function M.inherit_neighbor_attr(bufdoc, attrs, range3)
    log.assert(not bufdoc._tir, "inherit_neighbor_attr should be called only for bufdoc")
    if #bufdoc.blocks == 0 then
        return
    end
    local block = bufdoc.blocks[1]
    Block[block.kind].inherit_neighbor_attr(block, attrs, range3.first - 1)
    block = bufdoc.blocks[#bufdoc.blocks]
    Block[block.kind].inherit_neighbor_attr(block, attrs, range3.last + 1)
end

---@param bufdoc Document
function M.insert_empty_lines(bufdoc)
    log.assert(not bufdoc._tir, "insert_empty_lines should be called only for bufdoc")
    Blocks.insert_empty_lines(bufdoc.blocks)
end

---@param bufdoc Document
---@return boolean
function M.has_width(bufdoc)
    log.assert(not bufdoc._tir, "has_width should be called only for bufdoc")
    return Blocks.has_width(bufdoc.blocks)
end

return M
