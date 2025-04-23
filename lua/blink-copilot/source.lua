local util = require("blink-copilot.util")
local config = require("blink-copilot.config")

---@class BlinkCopilotProvider
---@field config Config
local M = {}

---The constructor for the completion provider
---@param opts Config
function M:new(opts)
	self:detect_lsp_client()
	self:reset(0)

	local source_config = vim.tbl_deep_extend("force", config.options, opts)
	source_config.max_attempts = source_config.max_attempts or source_config.max_completions + 1

	-- Unset the kind_name, kind_icon, and kind_hl if they are set to false
	for _, k in pairs({ "kind_name", "kind_icon", "kind_hl" }) do
		if source_config[k] == false then
			source_config[k] = nil
		end
	end

	return setmetatable({
		config = source_config,
	}, { __index = self })
end

---Detect the LSP client
function M:detect_lsp_client()
	if self.client and not self.client:is_stopped() then
		return
	end

	local lsp_clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/inlineCompletion" })
	for _, client in ipairs(lsp_clients) do
		if string.find(string.lower(client.name), "copilot") then
			self.client = client
			self.is_copilot_enabled = function()
				local copilot_lua, clt = pcall(require, "copilot.client")
				return (copilot_lua and clt and not clt.is_disabled()) or (vim.g.copilot_enabled ~= 0)
			end
			break
		end
	end
end

---Reset the context
---@param ts integer
function M:reset(ts)
	util.cancel_request(self.client, self.context and self.context.first_req_id)
	util.cancel_request(self.client, self.context and self.context.cycling_req_id)

	---@class CompletionContext
	self.context = {
		cache = {},
		completions = {},
		state = nil,
		first_req_id = nil,
		cycling_req_id = nil,
		start_ts = ts,
	}
end

---Add new completions to the context
---@param items blink.cmp.CompletionItem[]
function M:add_new_completions(items)
	local new_completions = {}

	for _, item in ipairs(items) do
		if #self.context.completions < config.options.max_completions then
			if not self.context.cache[item.label] then
				self.context.cache[item.label] = true
				table.insert(self.context.completions, item)
				table.insert(new_completions, item)
			end
		end
	end

	return new_completions
end

---Implement the get_completions method of the completion provider
---@param ctx blink.cmp.Context
---@param resolve fun(self: blink.cmp.CompletionResponse): nil
function M:get_completions(ctx, resolve)
	if not self.client or not self.is_copilot_enabled() then
		return
	end

	local current_state = { bufnr = ctx.bufnr, id = ctx.id, cursor = ctx.cursor }
	if vim.deep_equal(current_state, self.context.state) then
		resolve({
			is_incomplete_forward = self.config.auto_refresh.forward,
			is_incomplete_backward = self.config.auto_refresh.backward,
			items = self.context.completions,
		})
		return
	end

	local now = util.timestamp()

	if self.config.debounce ~= false and type(self.config.debounce) == "number" then
		local since = now - self.context.start_ts
		if since < self.config.debounce then
			if self.debounce_timer then
				self.debounce_timer:stop()
			end
			self.debounce_timer = vim.defer_fn(function()
				self.debounce_timer = nil
				self:get_completions(ctx, resolve)
			end, self.config.debounce)
			return
		end
	end

	self:reset(now)

	coroutine.wrap(function()
		local co = coroutine.running()
		local lsp_params = util.get_lsp_params()

		---@type lsp.Handler
		local function handle_lsp_response(err, response)
			coroutine.resume(co, not err and response and response.items)
		end

		---@param is_initial_request boolean
		local function send_completion_request(is_initial_request)
			local request_success, request_id =
				util.get_completions_from_lsp(self.client, lsp_params, handle_lsp_response)

			if request_success then
				if is_initial_request then
					self.context.first_req_id = request_id
				else
					self.context.cycling_req_id = request_id
				end
			end
			return request_success
		end

		local function process_and_resolve_items()
			local lsp_items = coroutine.yield()
			if self.context.start_ts ~= now or not lsp_items or #lsp_items == 0 then
				return
			end

			local blink_items = util.lsp_completion_items_to_blink_items(
				lsp_items,
				self.config.kind_name,
				self.config.kind_icon,
				self.config.kind_hl
			)

			resolve({
				is_incomplete_forward = self.config.auto_refresh.forward,
				is_incomplete_backward = self.config.auto_refresh.backward,
				items = self:add_new_completions(blink_items),
			})
		end

		-- Get the first completions
		if send_completion_request(true) then
			process_and_resolve_items()
			self.context.first_req_id = nil
			self.context.state = current_state
		end

		-- Attempt to get more completions
		lsp_params = util.to_cycling_lsp_params(lsp_params)
		local attempts_made = 0
		while
			now == self.context.start_ts -- If new blink request comes in, stop further attempts
			and #self.context.completions < self.config.max_completions
			and attempts_made < self.config.max_attempts
		do
			attempts_made = attempts_made + 1
			if send_completion_request(false) then
				process_and_resolve_items()
				self.context.cycling_req_id = nil
			end
		end
	end)()
end

return M
