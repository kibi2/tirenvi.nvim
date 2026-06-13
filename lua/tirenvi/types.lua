---@class Rect
---@field row Range
---@field col Range

---@class LineProvider
---@field get_line fun(row: integer): string|nil
---@field line_count fun(): integer
---@field get_lines fun(first: integer, last: integer): string[]

---@alias WidthMode
---| "auto"
---| "fit"
---| "max"
---| "fix"
