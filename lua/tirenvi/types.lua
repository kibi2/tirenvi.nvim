---@meta

---@alias Ndjson Attr_file | Attr | Record

---@alias Blocks Block[]

---@alias Block
---| Block_plain
---| Block_grid

---@alias BlockKind
---| "plain"
---| "grid"

---@class Block_plain
---@field kind "plain"
---@field attr Attr_plain
---@field records Record_plain[]

---@class Block_grid
---@field kind "grid"
---@field attr Attr_grid
---@field records Record_grid[]

---@class Attr_file
---@field kind "attr_file"
---@field version string

---@alias Attr Attr_plain | Attr_grid

---@class Attr_plain
---@field kind "attr_plain"

---@class Attr_grid
---@field kind "attr_grid"
---@field columns? Attr_column[]

---@class Attr_column
---@field width? integer  -- display width (logical column width)
---@field align? Align

---@alias Align "left" | "center" | "right" | "default"

---@alias Record Record_plain | Record_grid

---@class Record_plain
---@field kind "plain"
---@field line string

---@class Record_grid
---@field kind "grid"
---@field row Cell[]

---@alias Cell string

---@class Parser
---@field executable string      Parser executable name
---@field options string[]       Command-line arguments passed to the parser
---@field allow_plain? boolean   Whether plain blocks are allowed (GFM). If false, only a single table is permitted.

---@class Marks
---@field pipe string
---@field padding string
---@field trim string
---@field lf string
---@field tab string

---@class Check_options
---@field unsupported? boolean
---@field ensure_tir_vim? boolean
---@field is_tir_vim? boolean
---@field has_parser? boolean
---@field already_invalid? boolean
