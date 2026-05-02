local CONST = require("tirenvi.constants")
local Blocks = require("tirenvi.core.blocks")
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
---@field _attr_build Attr

---@class Attr_file
---@field kind "attr_file"
---@field version string

---@class Attr_doc
---@field allow_plain boolean
---@field attrs_in Attr[]
---@field attrs_out Attr[]

---@class Attr
---@field id integer
---@field range Range
---@field max boolean
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

local VERSION = "tir/0.1"

-- private helpers

---@return Ndjson
local function new_attr_file()
    return { kind = CONST.KIND.ATTR_FILE, version = VERSION }
end

-- Public API

---@param ndjsons Ndjson[]
---@param allow_plain boolean
---@return Document
function M.new_from_flat(ndjsons, allow_plain)
    local self = {}
    self.attr = { allow_plain = allow_plain }
    self.blocks = Blocks.new_from_records(ndjsons, allow_plain)
    Blocks.from_flat(self.blocks)
    return self
end

---@param self Document
---@return Document
function M:to_flat()
    Blocks.to_flat(self.blocks)
    return self
end

---@param self Document
---@return Ndjson[]
function M:serialize_to_flat()
    local ndjsons = { new_attr_file() }
    util.extend(ndjsons, Blocks.serialize(self.blocks))
    return ndjsons
end

---@param records Record[]
---@param allow_plain boolean
---@return Document
function M.new_vim_doc(records, allow_plain)
    local self = {}
    self.attr = { allow_plain = allow_plain }
    self.blocks = Blocks.new_from_records(records, allow_plain)
    return self
end

---@param self Document
---@param no_normalize boolean  -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
function M.from_vim_doc(self, no_normalize)
    Blocks.from_vim(self.blocks, no_normalize)
end

---@param self Document
---@return Document
function M:to_vim_doc()
    Blocks.to_vim(self.blocks)
    return self
end

---@param self Document
---@return Ndjson[]
function M:serialize()
    return Blocks.serialize(self.blocks)
end

---@param self Document
---@param attr_prev Attr|nil
---@param attr_next Attr|nil
---@return boolean
---@return RefAttrError|nil
function M:reconcile(attr_prev, attr_next)
    if self.attr.allow_plain then
        return Blocks.reconcile_multi(self.blocks, attr_prev, attr_next)
    else
        return Blocks.reconcile_single(self.blocks, attr_prev, attr_next)
    end
end

---@param self Document
---@return Attr[]
function M:collect_attrs()
    return Blocks.get_attrs(self.blocks)
end

---@param self Document
function M:rebuild_attrs(first)
    Blocks.rebuild_attrs(self.blocks, first)
end

---@param self Document
function M:set_attrs_in(attrs)
    self.attr.attrs_in = attrs
end

---@param self Document
function M:apply_attrs()
    Blocks.apply_attrs(self.blocks, self.attr.attrs_in)
end

return M
