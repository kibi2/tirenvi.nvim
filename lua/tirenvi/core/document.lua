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

---@param records Record[]
---@param allow_plain boolean
---@param attrs Attr[]|nil
---@return Document
local function new(records, allow_plain, attrs)
    local self = {}
    self.attr = { allow_plain = allow_plain }
    self.blocks = Blocks.new_from_records(records, allow_plain, attrs)
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

-- Public API

---@param ndjsons Ndjson[]
---@param allow_plain boolean
---@return Document
function M.new_tirdoc(ndjsons, allow_plain)
    local self = new(ndjsons, allow_plain)
    Blocks.from_flat(self.blocks)
    return self
end

---@param records Record[]
---@param allow_plain boolean
---@param attrs Attr[]|nil
---@return Document
function M.new_bufdoc(records, allow_plain, attrs)
    return new(records, allow_plain, attrs)
end

---@param self Document
---@param no_normalize boolean|nil  -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document
function M.from_bufdoc(self, no_normalize)
    no_normalize = no_normalize or false
    local doc = vim.deepcopy(self)
    Blocks.from_buf(doc.blocks, no_normalize)
    return doc
end

---@param self Document
---@return Document
function M:to_tirdoc()
    Blocks.to_flat(self.blocks)
    return self
end

---@param tirdoc Document
---@return Document
function M.to_bufdoc(tirdoc)
    local bufdoc = vim.deepcopy(tirdoc)
    Blocks.to_bufdoc(bufdoc.blocks)
    return bufdoc
end

---@param self Document
---@return Ndjson[]
function M:serialize()
    return Blocks.serialize(self.blocks)
end

---@param self Document
---@return Ndjson[]
function M:serialize_to_flat()
    local ndjsons = { new_attr_file() }
    util.extend(ndjsons, Blocks.serialize(self.blocks))
    return ndjsons
end

---@param self Document
---@param range Range
---@param chached_attrs Attr[]
---@return Attr[]
function M:replace_attrs(range, chached_attrs)
    local doc_attrs = Blocks.collect_attrs(self.blocks)
    if not chached_attrs or Range.is_whole(range) then
        return doc_attrs
    end
    return Attrs.replace_attrs(chached_attrs, range, doc_attrs)
end

---@param self Document
function M:infer_consistent_attr()
    Blocks.infer_consistent_attr(self.blocks)
end

---@param self Document
function M:set_auto_attr()
    Blocks.set_auto_attr(self.blocks)
end

---@param bufdoc Document
function M.set_attr_range(bufdoc, first)
    Blocks.set_attr_range(bufdoc.blocks, first)
end

---@param self Document
---@param attrs Attr[]
function M:apply_cached_attr(attrs)
    Blocks.apply_cached_attr(self.blocks, attrs)
end

---@param self Document
---@param attrs Attr[]
function M:apply_attrs_by_id(attrs)
    local attrs_grid = Attrs.get_grid_attrs(attrs)
    local iblock = 0
    for _, block in ipairs(self.blocks) do
        block.attr = Attr[block.kind].new()
        if block.kind == CONST.KIND.GRID then
            iblock = iblock + 1
            if attrs_grid[iblock] then
                block.attr.columns = attrs_grid[iblock].columns
            end
        end
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

---@param self Document
---@param attrs Attr[]
---@param range3 Range3
function M:inherit_neighbor_attr(attrs, range3)
    if #self.blocks == 0 then
        return
    end
    local block = self.blocks[1]
    Block[block.kind].inherit_neighbor_attr(block, attrs, range3.first - 1)
    block = self.blocks[#self.blocks]
    Block[block.kind].inherit_neighbor_attr(block, attrs, range3.last + 1)
end

---@param self Document
function M:insert_empty_lines()
    Blocks.insert_empty_lines(self.blocks)
end

---@param self Document
---@return boolean
function M:has_width()
    return Blocks.has_width(self.blocks)
end

return M
