--- Configuration management for tirenvi.

local levels = vim.log.levels

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Marks
---@field pipe string
---@field padding string
---@field pipec string
---@field lf string
---@field tab string

---@class Parser
---@field executable string             Parser executable name
---@field options? string[]             Command-line arguments passed to the parser
---@field required_version? string      Parser required version "major.minor.patch"
---@field _iversion? integer            integer version
---@field allow_plain? boolean          Whether plain blocks are allowed (GFM). If false, only a single table is permitted.

-----------------------------------------------------------------------
-- Defaults
-----------------------------------------------------------------------

local defaults = {
	---@type Marks
	marks = {
		pipe = "│", -- │┆┊┇┃┋▏▕
		padding = "⠀", --    ·∙⸱␣␠⠀░
		pipec = "┊", -- 》⇥⇢⋯⋮︙›↠▶¬…
		lf = "↲", -- ⤶⏎↵↲⤷␤¶—↩️
		tab = "⇥", -- »⇥→⇨▹▸▻►⇤␉》
	},
	---@type {[string]: Parser}
	parser_map = {
		csv = { executable = "tir-csv", required_version = "0.1.4" },
		tsv = { executable = "tir-csv", options = { "--delimiter", "\t" }, required_version = "0.1.4" },
		markdown = { executable = "tir-gfm-lite", allow_plain = true, required_version = "0.1.5" },
		pukiwiki = { executable = "tir-pukiwiki", allow_plain = true, required_version = "0.1.1" },
	},
	textobj = {
		column = "l",
	},
	table = {
		auto_reconcile = true,
	},
	ui = {
		conceal = {
			level = 1,
			cursor = "nvic",
		}
	},
	log = {
		level = levels.WARN,
		single_line = true,
		output = "notify", -- "notify" | "buffer" | "print" | "file"
		buffer_name = "tirenvi://log",
		file_name = "/tmp/tirenvi.log",
		use_timestamp = false,
		monitor = true,
		probe = false,
	},
}

-----------------------------------------------------------------------
-- Initialize with defaults
-----------------------------------------------------------------------

---@param opts {[string]:any}
local function apply(opts)
	for key, value in pairs(opts) do
		M[key] = value
	end
end

---@param parser_map Parser[]
local function parse_version(parser_map)
	for _, parser in pairs(parser_map) do
		parser._iversion = M.version_to_integer(parser.required_version)
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param opts {[string]:any}
function M.setup(opts)
	local merged = vim.tbl_deep_extend("force", {}, M, opts or {})
	apply(merged)
	parse_version(M.parser_map)
end

---@param version any
---@return integer|nil
function M.version_to_integer(version)
	if type(version) ~= "string" then
		return nil
	end
	local major, minor, patch = version:match("^(%d+)%.(%d+)%.?(%d*)$")
	if not major then
		return nil
	end
	local maj, min, pat = tonumber(major), tonumber(minor), tonumber(patch) or 0
	return (maj * 100000 + min) * 100000 + pat
end

apply(vim.deepcopy(defaults))

return M
