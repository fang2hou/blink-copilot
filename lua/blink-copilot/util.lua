local M = {}

---@enum trigger_kind
local trigger_kind = {
	inline_invoked = 1,
	inline_automatic = 2,
}

---Cancel the LSP request
---@param client vim.lsp.Client
---@param req_id integer?
function M.cancel_request(client, req_id)
	if client and req_id then
		client.cancel_request(req_id)
	end
end

---Get the LSP params for the first completion
function M.get_lsp_params()
	return vim.tbl_deep_extend("force", vim.lsp.util.make_position_params(0, "utf-16"), {
		formattingOptions = {
			insertSpaces = vim.bo.expandtab,
			tabSize = vim.bo.shiftwidth,
		},
		context = {
			triggerKind = trigger_kind.inline_automatic,
		},
	})
end

---Convert the params from first completion to cycling completion
---@param params table
function M.to_cycling_lsp_params(params)
	return vim.tbl_deep_extend("force", params, {
		context = {
			triggerKind = trigger_kind.inline_invoked,
		},
	})
end

---Get the completions from Copilot LSP
---The arguments from copilot.vim
---@param client vim.lsp.Client
---@param params table
---@param cb lsp.Handler
function M.get_completions_from_lsp(client, params, cb)
	return client.request("textDocument/inlineCompletion", params, cb)
end

---Recalculate the length of the first line of the text
---Modified from copilot-cmp
---@param text string
---@param sep? string
---@return integer
function M.length_of_first_line(text, sep)
	sep = sep or (text:find("\r") and "\r" or "\n") or "\n"

	if not string.find(text, "[\r|\n]") then
		return #text
	end

	local matched = string.match(text, "([^" .. sep .. "]+)")
	return matched and #matched or #text
end

---Remove the common indent from the text
---@param text string
---@return string
function M.deindent(text)
	local lines = vim.split(text, "\n")

	-- Cleanup the empty lines
	local start_idx, end_idx = 1, #lines
	while start_idx <= #lines and lines[start_idx] == "" do
		start_idx = start_idx + 1
	end
	if start_idx > #lines then
		return ""
	end
	while end_idx >= 1 and lines[end_idx] == "" do
		end_idx = end_idx - 1
	end

	lines = vim.list_slice(lines, start_idx, end_idx)

	-- Find the common indent
	local indents = {}
	for _, line in ipairs(lines) do
		if line ~= "" then
			local indent = line:match("^%s*")
			table.insert(indents, indent)
		end
	end
	if #indents == 0 then
		return table.concat(lines, "\n")
	end

	local common_prefix = indents[1]
	for i = 2, #indents do
		local current_indent = indents[i]
		local min_len = math.min(#common_prefix, #current_indent)
		local new_prefix = ""
		for j = 1, min_len do
			if common_prefix:sub(j, j) == current_indent:sub(j, j) then
				new_prefix = new_prefix .. common_prefix:sub(j, j)
			else
				break
			end
		end
		common_prefix = new_prefix
		if common_prefix == "" then
			break
		end
	end

	local processed_lines = {}
	for _, line in ipairs(lines) do
		if line == "" then
			table.insert(processed_lines, "")
		else
			local processed_line = line:gsub("^" .. common_prefix, "", 1)
			table.insert(processed_lines, processed_line)
		end
	end

	return table.concat(processed_lines, "\n")
end

---Transforms a Copilot completion items to blink completion item
---@param completions table[]
---@param kind_name string
---@param kind_icon string
---@return blink.cmp.CompletionItem[]
function M.lsp_completion_items_to_blink_items(completions, kind_name, kind_icon)
	---@type blink.cmp.CompletionItem[]
	local items = {}

	for _, completion in ipairs(completions) do
		-- The original range is the cursor position, so we need to update it to the end of the line
		completion.range["end"].character = M.length_of_first_line(completion.insertText)

		local dedented_text = M.deindent(completion.insertText)

		table.insert(items, {
			label = dedented_text,
			kind_name = kind_name,
			kind_icon = kind_icon,
			textEdit = { newText = completion.insertText, range = completion.range },
			detail = dedented_text,
		})
	end

	return items
end

---Get the current time in milliseconds
---@return integer timestamp
function M.timestamp()
	---@diagnostic disable-next-line: undefined-field
	return math.floor(vim.loop.hrtime() / 1e6)
end

return M
