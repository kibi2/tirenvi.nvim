-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local config = require("tirenvi.config")
local buffer = require("tirenvi.state.buffer")
local errors = require("tirenvi.util.errors")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Parser
---@field executable string             Parser executable name
---@field options? string[]             Command-line arguments passed to the parser
---@field required_version? string      Parser required version "major.minor.patch"
---@field allow_plain? boolean          Whether plain blocks are allowed (GFM). If false, only a single table is permitted.
---@field _required_version_int? integer required version
---@field _installed_version? string    installed version
---@field _err_code? string             error code
---@field _checked? boolean             is checked

local ERR = {
    EXECUTABLE_NOT_FOUND = "executable_not_found",
    VERSION_COMMAND_FAILED = "version_command_failed",
    VERSION_PARSE_FAILED = "version_parse_failed",
    VERSION_TOO_OLD = "version_too_old",
}
M.ERR = ERR
local fn = vim.fn

-- private helpers

--- Get parser configuration for a file.
---@param filetype string|nil
---@return Parser|nil
local function get_parser_for_filetype(filetype)
    if not filetype then
        return nil
    end
    local parser = config.parser_map[filetype]
    if not parser or not parser.executable then
        return nil
    end
    return parser
end

---@param command string[]
---@param input string[]
---@return Vim_system
local function vim_system(command, input)
    log.debug("=== === === [exec] %s === === ===", table.concat(command, " "))
    local result = vim.system(command, { stdin = input }):wait()
    if result.stdout and #result.stdout > 0 then
        log.debug(util.to_hex(result.stdout):sub(1, 80) .. " ")
    end
    return result
end

---@param self Parser
local function ensure_parser(self)
    if not self._err_code then
        return
    end
    local message
    if self._err_code == ERR.EXECUTABLE_NOT_FOUND then
        message = errors.not_found_parser_error(self)
    elseif self._err_code == ERR.VERSION_TOO_OLD then
        message = errors.outdated_parser_error(self)
    else
        message = errors.no_parser_error()
    end
    error(errors.new_domain_error(message))
end

--- run external parser command
---@param executable string Parser command
---@param subcmd string Subcommand ("parse" or "unparse")
---@param options string[] Command options
---@param lines string[] Input lines
---@return string stdout
local function run_parser(executable, subcmd, options, lines)
    local command = { executable, subcmd }
    if options then
        vim.list_extend(command, options)
    end
    local result = vim_system(command, lines)
    if result.code ~= 0 then
        error(errors.new_domain_error(errors.vim_system_error(result, command)))
    end
    return result.stdout
end

---@param self Parser
---@return string|nil
local function get_string_version(self)
    if fn.executable(self.executable) ~= 1 then
        error({ code = ERR.EXECUTABLE_NOT_FOUND })
    end
    self._installed_version = vim.trim(fn.system({ self.executable, "--version" }))
    if vim.v.shell_error ~= 0 then
        error({ code = ERR.VERSION_COMMAND_FAILED })
    end
    return self._installed_version
end

---@param self Parser
---@return integer|nil
local function get_int_version(self)
    local str_ver = get_string_version(self)
    local int_ver = config.version_to_integer(str_ver)
    if not int_ver then
        error({ code = ERR.VERSION_PARSE_FAILED })
    end
    return int_ver
end

---@return boolean
local function is_available_version(self)
    local iver = get_int_version(self)
    if iver < self._required_version_int then
        error({ code = ERR.VERSION_TOO_OLD })
    end
    return true
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param self Parser
---@param subcmd string Subcommand ("parse" or "unparse")
---@param lines string[] Input lines
---@return string stdout
function M.run(self, subcmd, lines)
    ensure_parser(self)
    return run_parser(self.executable, subcmd, self.options, lines)
end

---@param self Parser
---@return boolean
---@return string|nil
function M.check(self)
    if self._checked then
        return self._err_code == nil, self._err_code
    end
    local ok, err = pcall(is_available_version, self)
    self._checked = true
    local error_code
    if not ok then
        if type(err) == "table" and err.code then
            error_code = err.code
        else
            error_code = tostring(err)
        end
    end
    return ok, error_code
end

---@param filetype string|nil
---@return Parser|nil
function M.resolve_parser(filetype)
    local parser = get_parser_for_filetype(filetype)
    if not parser then
        return nil
    end
    _, parser._err_code = M.check(parser)
    return parser
end

return M
