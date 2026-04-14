--- Centralized error definitions and error message builders for tirenvi.
---
--- This module:
---   - Defines domain error tag
---   - Provides user-facing error message builders
---   - Centralizes all error strings
---

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-----------------------------------------------------------------------
-- Domain error tag
-----------------------------------------------------------------------

--- Unique tag used to identify domain validation errors.
M.DOMAIN_ERROR = {}

-----------------------------------------------------------------------
-- Static error messages
-----------------------------------------------------------------------
local PREFIX = "tirenvi: "
M.ERR = {
	INVALID_TABLE_MESSAGE = PREFIX .. "This change would break the table structure. Changes have been undone.",
	ENSURE_TIRVIM_MODE = PREFIX .. "This command is only available in a tir-vim buffer.",
}

-----------------------------------------------------------------------
-- Error builders
-----------------------------------------------------------------------

--- Create a domain error object.
---@param message string
---@param kind string|nil
---@return { tag: table, message: string, kind: string? }
function M.new_domain_error(message, kind)
	return {
		tag = M.DOMAIN_ERROR,
		message = message,
		kind = kind,
	}
end

--- No usable characters available.
---@param missing string[]
---@return string
function M.err_no_usable_characters(missing)
	return string.format(
		PREFIX
		.. "No usable characters found for marks: [%s].\n"
		.. "Please configure alternative characters in tirenvi.setup().",
		table.concat(missing, ", ")
	)
end

--- Unknown Tir command.
---@param sub_command string
---@return string
function M.err_unknown_command(sub_command)
	return PREFIX .. "Unknown Tir command: " .. sub_command
end

--- External command execution failed.
---@param system { code: integer, signal?: integer, stdout?: string?, stderr?: string? }
---@param command string[]
---@return string
function M.vim_system_error(system, command)
	local stderr = system.stderr
	if not stderr or stderr == "" then
		stderr = "(no stderr output)"
	end

	return string.format(
		PREFIX .. "External command failed\n\n" .. "Command:\n  %s\n\n" .. "Exit code: %d\n\n" .. "Error output:\n%s",
		table.concat(command, " "),
		system.code,
		stderr
	)
end

--- No parser configured for extension.
---@param ext string|nil
---@return string
function M.no_parser_error(ext)
	return string.format(PREFIX .. "No parser available for extension '%s'.", ext)
end

--- Parser command not found in PATH.
---@param parser Parser
---@return string
function M.not_found_parser_error(parser)
	return string.format(
		PREFIX .. "Required command '%s' not found in PATH.\n\n" .. "Use :checkhealth tirenvi for details.",
		parser.executable
	)
end

---@param js_line string
---@param message string
---@return string
function M.invalid_json_error(js_line, message)
	return string.format(PREFIX .. "tirenvi: invalid JSON from parser\n%s\nerror: %s", js_line, message)
end

return M
