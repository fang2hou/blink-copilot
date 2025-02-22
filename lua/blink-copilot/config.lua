local M = {}

---@class Config
---@field max_completions integer Maximum number of completions to show
---@field max_attempts? integer Maximum number of attempts to fetch completions
---@field kind_name string The name of the kind
---@field kind_icon string The icon of the kind
---@field debounce integer|false Debounce time in milliseconds
---@field auto_refresh? {backward?: boolean, forward?: boolean} Whether to auto-refresh completions
M.options = {
	max_completions = 3,
	kind_name = "Copilot",
	kind_icon = "",
	debounce = 200,
	auto_refresh = {
		backward = true,
		forward = true,
	},
}

---Merge the user options with the default options
---@param user_opts Config
function M.init(user_opts)
	M.options = vim.tbl_deep_extend("force", M.options, user_opts)
end

return M
