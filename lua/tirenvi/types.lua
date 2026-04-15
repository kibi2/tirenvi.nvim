---@meta

---@alias Ndjson Attr_file|Record

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

---@class Parser
---@field executable string             Parser executable name
---@field options? string[]             Command-line arguments passed to the parser
---@field required_version? string      Parser required version "major.minor.patch"
---@field _iversion? integer            integer version
---@field allow_plain? boolean          Whether plain blocks are allowed (GFM). If false, only a single table is permitted.

---@class Marks
---@field pipe string
---@field padding string
---@field pipec string
---@field lf string
---@field tab string

---@class Check_options
---@field supported? boolean
---@field ensure_tir_vim? boolean
---@field is_tir_vim? boolean
---@field has_parser? boolean
---@field no_vscode? boolean

---@class Rect
---@field row Range
---@field col Range

---@class LineProvider
---@field get_line fun(row: integer): string|nil
---@field line_count fun(): integer
