---@meta

---@alias Ndjson Attr_file|Record

---@class Rect
---@field row Range
---@field col Range

---@class LineProvider
---@field get_line fun(row: integer): string|nil
---@field line_count fun(): integer
