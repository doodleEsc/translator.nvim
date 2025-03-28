local M = {}
local api = require("translator.api")
local ui = require("translator.ui")
local config = require("translator.config")

---Setup the translator plugin with the given options
---@param opts table|nil Configuration options for the plugin
---@return nil
function M.setup(opts)
	config.setup(opts)
	-- Create user command, only available in visual mode
	vim.api.nvim_create_user_command("Translate", function()
		require("translator").translate()
	end, { range = true })

	-- Set default keymaps for visual mode
	if config.options.keymaps.enable then
		vim.api.nvim_set_keymap(
			"v",
			config.options.keymaps.translate,
			":Translate<CR>",
			{ noremap = true, silent = true }
		)
	end
end

---Translate the selected text using the configured translation engine
---This function handles both streaming and non-streaming translation modes
---@return nil
function M.translate()
	-- Get the selected text
	local text = M.get_visual_selection()
	if not text or text == "" then
		vim.notify("No text selected", vim.log.levels.ERROR)
		return
	end

	-- Show floating window with source text
	local ui_handler = ui.create_floating_window(text)

	-- Use streaming or regular translation based on configuration
	if config.options.streaming then
		api.stream_translate(text, function(chunk, source_lang)
			ui.update_translation(ui_handler, chunk, source_lang, true)
		end)
	else
		api.translate(text, function(translation, source_lang)
			ui.update_translation(ui_handler, translation, source_lang, false)
		end)
	end
end

---Get the text selected in visual mode
---Handles both regular visual selection and V-LINE mode
---@return string selected_text The text that was selected in visual mode
function M.get_visual_selection()
	local _, start_line, start_col, _ = unpack(vim.fn.getpos("'<"))
	local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))

	-- Handle V-LINE mode selection
	if start_line == end_line and start_col == end_col then
		local line = vim.fn.getline(".")
		return line
	end

	local lines = vim.fn.getline(start_line, end_line)

	if #lines == 0 then
		return ""
	end

	-- Handle partial selection of first and last lines
	lines[1] = string.sub(lines[1], start_col)
	lines[#lines] = string.sub(lines[#lines], 1, end_col)

	return table.concat(lines, "\n")
end

return M
