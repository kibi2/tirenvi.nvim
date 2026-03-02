---@meta

---@alias Blocks Block[]

---@alias Block
---| Block_file_attr
---| Block_plain
---| Block_grid

---@alias BlockElement_plain Record_plain|Record_block_start
---@alias BlockElement_grid  Record_grid|Record_block_start

-- TODO: structure
---@alias Block_file_attr Record_file_attr[]
---@alias Block_plain BlockElement_plain[]
---@alias Block_grid  BlockElement_grid[]

---@alias Record
---| Record_file_attr
---| Record_block_start
---| Record_plain
---| Record_grid

---@class Record_file_attr
---@field kind "file_attr"
---@field version string
---@field file_path string
---@field [string] any

---@class Record_block_start
---@field kind "block_start"
---@field attr? any
---@field [string] any

---@class Record_plain
---@field kind "plain"
---@field line string
---@field [string] any

---@class Record_grid
---@field kind "grid"
---@field row string[]
---@field [string] any

---@class Parser
---@field executable string  Parser executable name
---@field options string[]  Command-line arguments passed to the parser

---@class Marks
---@field pipe string
---@field padding string
---@field trim string
---@field lf string
---@field tab string

---@class Check_options
---@field unsupported? any
---@field ensure_tir_vim? any
---@field is_tir_vim? any
---@field has_parser? any
---@field already_invalid? any

---@alias Cell string
