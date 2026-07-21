-- =============================================================================

local M = {}

--- Unique tag used to identify domain validation errors.
M.DOMAIN_ERROR = {}

local PREFIX = "tirenvi: "
M.ERR = {
	INVALID_TABLE_MESSAGE = PREFIX .. "This change would break the table structure. Changes have been undone.",
	ENSURE_TIRVIM_MODE = PREFIX .. "This command is only available in a tir-vim buffer.",
	TABLE_IS_NOT_ALIGNED = PREFIX .. "Cannot select column: table is not aligned.",
}

-- =============================================================================
-- Public API

--- Create a domain error object.
---@param message string
---@return { tag: table, message: string}
function M.new_domain_error(message)
	return {
		tag = M.DOMAIN_ERROR,
		message = message,
	}
end

--- No usable characters available.
---@param missing string[]
---@return string
function M.err_no_usable_characters(missing)
	table.sort(missing)
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
function M.err_invalid_command(sub_command)
	return PREFIX .. "Invalid Tir command: " .. sub_command
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

--- Parser command not found in PATH.
---@param executable string
---@return string
function M.not_found_parser_error(executable)
	return string.format(
		PREFIX .. "Required command '%s' not found.\n\n" .. "Install it with:\n\n" .. "    pip install %s",
		executable,
		executable
	)
end

--- Parser version is too old.
---@param executable string
---@param required_version string
---@param installed_version string
---@return string
function M.outdated_parser_error(executable, required_version, installed_version)
	return string.format(
		PREFIX
		.. "Command '%s' version is too old.\n\n"
		.. "Required version: %s\n"
		.. "Installed version: %s\n\n"
		.. "Use :checkhealth tirenvi for details.",
		executable,
		required_version or "unknown",
		installed_version or "unknown"
	)
end

---@param jsline string
---@param message string
---@return string
function M.invalid_json_error(jsline, message)
	return string.format(PREFIX .. "tirenvi: invalid JSON from parser\n%s\nerror: %s", jsline, message)
end

function M.table_merge_warning(irow)
	return string.format(
		PREFIX .. "Tables were not merged: talble attribute differ in line %d-%d.\n" ..
		"Align the table attribute to merge them.", irow, irow + 2)
end

return M
