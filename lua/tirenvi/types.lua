---@meta

---@alias Ndjson Attr_file | Record

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

---@class Attr
---@field columns Attr_column[]

---@class Attr_column
---@field width? integer  -- display width (logical column width)
---@field align? Align

---@alias Align "left" | "center" | "right"

---@alias Record Record_plain | Record_grid

---@class Record_plain
---@field kind "plain"
---@field line string

---@class Record_grid
---@field kind "grid"
---@field row Cell[]

---@alias Cell string

---@class Parser
---@field executable string             Parser executable name
---@field options string[]              Command-line arguments passed to the parser
---@field required_version? integer[]   Parser required version [ major, minor, patch ]
---@field allow_plain? boolean          Whether plain blocks are allowed (GFM). If false, only a single table is permitted.

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
