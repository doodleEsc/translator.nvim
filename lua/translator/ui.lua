local M = {}
local config = require("translator.config")
local Popup = require("nui.popup")
local Layout = require("nui.layout")

-- Store the current active window handles
M.active_windows = nil

-- Create translation window
function M.create_floating_window(source_text)
	-- If there's an active window, destroy it first
	if M.active_windows and M.active_windows.layout then
		pcall(function()
			M.active_windows.layout:unmount()
		end)
		M.active_windows = nil
	end
	-- Convert percentage to actual pixel values
	local width = math.floor(vim.o.columns * config.options.ui.width)
	local height = math.floor(vim.o.lines * config.options.ui.height)

	-- Create source text window
	local source_popup = Popup({
		enter = false,
		border = {
			style = config.options.ui.border.style,
			text = {
				top = config.options.ui.border.text.top_source,
				top_align = config.options.ui.border.text.top_align,
			},
		},
		buf_options = {
			modifiable = false,
			readonly = true,
			filetype = "translator-source",
		},
		win_options = {
			wrap = true,
			cursorline = false,
			scrolloff = 1,
		},
	})

	-- Create translation text window
	local translation_popup = Popup({
		enter = true,
		border = {
			style = config.options.ui.border.style,
			text = {
				top = config.options.ui.border.text.top_target,
				top_align = config.options.ui.border.text.top_align,
			},
		},
		buf_options = {
			modifiable = false,
			readonly = true,
			filetype = "translator",
		},
		win_options = {
			wrap = true,
			cursorline = false,
			scrolloff = 1,
		},
	})

	-- Create layout
	local layout = Layout(
		{
			position = "50%",
			size = {
				width = width,
				height = height,
			},
		},
		Layout.Box({
			Layout.Box(source_popup, { size = "50%" }),
			Layout.Box(translation_popup, { size = "50%" }),
		}, { dir = "row" })
	)

	-- Mount layout
	layout:mount()

	-- Set source text content
	source_popup:map("n", "q", function()
		layout:unmount()
	end, { noremap = true })

	source_popup:map("n", "<Esc>", function()
		layout:unmount()
	end, { noremap = true })

	translation_popup:map("n", "q", function()
		layout:unmount()
	end, { noremap = true })

	translation_popup:map("n", "<Esc>", function()
		layout:unmount()
	end, { noremap = true })

	-- Fill source text content
	-- Temporarily set as modifiable
	vim.api.nvim_set_option_value("modifiable", true, { buf = source_popup.bufnr })
	vim.api.nvim_set_option_value("readonly", false, { buf = source_popup.bufnr })
	vim.api.nvim_buf_set_lines(source_popup.bufnr, 0, -1, false, vim.split(source_text, "\n"))
	vim.api.nvim_set_option_value("modifiable", false, { buf = source_popup.bufnr })
	vim.api.nvim_set_option_value("readonly", true, { buf = source_popup.bufnr })

	-- Store and return window handles
	M.active_windows = {
		source_bufnr = source_popup.bufnr,
		translation_bufnr = translation_popup.bufnr,
		source_winnr = source_popup.winid,
		translation_winnr = translation_popup.winid,
		layout = layout,
	}
	return M.active_windows
end

-- Update translation content
function M.update_translation(ui_handles, translation, header, is_streaming)
	local translation_bufnr = ui_handles.translation_bufnr

	if not vim.api.nvim_buf_is_valid(translation_bufnr) then
		return
	end

	-- 临时设置为可修改
	vim.api.nvim_set_option_value("modifiable", true, { buf = translation_bufnr })
	vim.api.nvim_set_option_value("readonly", false, { buf = translation_bufnr })

	-- Append new content to buffer
	ui_handles.content = (ui_handles.content or "") .. translation

	-- Replace content (starting from line 3)
	vim.api.nvim_buf_set_lines(translation_bufnr, 0, -1, false, vim.split(ui_handles.content, "\n"))

	-- Restore to read-only
	vim.api.nvim_set_option_value("modifiable", false, { buf = translation_bufnr })
	vim.api.nvim_set_option_value("readonly", true, { buf = translation_bufnr })

	-- If streaming output, scroll to bottom
	if is_streaming and ui_handles.translation_winnr then
		local line_count = vim.api.nvim_buf_line_count(translation_bufnr)
		vim.api.nvim_win_set_cursor(ui_handles.translation_winnr, { line_count, 0 })
	end
end

-- Height calculation function is no longer needed as we use fixed height and scrollbars
function M.calculate_height(text, width)
	-- 为了兼容性保留此函数，但不再使用其计算结果
	local lines = vim.split(text, "\n")
	local height = 0

	for _, line in ipairs(lines) do
		local line_length = vim.fn.strdisplaywidth(line)
		local line_height = math.ceil(line_length / width)
		height = height + math.max(1, line_height)
	end

	return height
end

return M
