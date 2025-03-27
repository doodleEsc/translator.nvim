local M = {}
local config = require("translator.config")
local Popup = require("nui.popup")
local Split = require("nui.split")
local Layout = require("nui.layout")
local event = require("nui.utils.autocmd").event

-- 创建翻译窗口
function M.create_floating_window(source_text)
	local width = config.options.window_width
	local height = math.floor(vim.o.lines * 0.8) -- 固定高度为屏幕高度的80%
	-- local height = config.options.window_width

	-- 创建源文本窗口
	local source_popup = Popup({
		enter = false,
		border = {
			style = "rounded",
			text = {
				top = " Source ",
				top_align = "center",
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

	-- 创建翻译文本窗口
	local translation_popup = Popup({
		enter = true,
		border = {
			style = "rounded",
			text = {
				top = " Translation ",
				top_align = "center",
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

	-- 创建布局
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

	-- 挂载布局
	layout:mount()

	-- 设置源文本内容
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

	-- 填充源文本内容
	-- 临时设置为可修改
	vim.api.nvim_set_option_value("modifiable", true, { buf = source_popup.bufnr })
	vim.api.nvim_set_option_value("readonly", false, { buf = source_popup.bufnr })
	vim.api.nvim_buf_set_lines(source_popup.bufnr, 0, -1, false, vim.split(source_text, "\n"))
	vim.api.nvim_set_option_value("modifiable", false, { buf = source_popup.bufnr })
	vim.api.nvim_set_option_value("readonly", true, { buf = source_popup.bufnr })
	-- 返回翻译窗口的缓冲区和窗口ID以及布局对象
	return {
		source_bufnr = source_popup.bufnr,
		translation_bufnr = translation_popup.bufnr,
		source_winnr = source_popup.winid,
		translation_winnr = translation_popup.winid,
		layout = layout,
	}
end

-- 更新翻译内容
function M.update_translation(ui_handles, translation, header, is_streaming)
	local translation_bufnr = ui_handles.translation_bufnr

	if not vim.api.nvim_buf_is_valid(translation_bufnr) then
		return
	end

	-- 临时设置为可修改
	vim.api.nvim_set_option_value("modifiable", true, { buf = translation_bufnr })
	vim.api.nvim_set_option_value("readonly", false, { buf = translation_bufnr })

	-- -- 如果是第一次更新，清除初始内容并设置头部
	-- if not ui_handles.initialized then
	-- 	vim.api.nvim_buf_set_lines(translation_bufnr, 0, -1, false, {})
	--
	-- 	-- 添加语言信息行
	-- 	if header and header ~= "" then
	-- 		vim.api.nvim_buf_set_lines(translation_bufnr, 0, 0, false, { header, "" })
	-- 	else
	-- 		vim.api.nvim_buf_set_lines(translation_bufnr, 0, 0, false, { "Detecting language...", "" })
	-- 	end
	--
	-- 	-- -- 设置语言信息行高亮
	-- 	-- local ns_id = vim.api.nvim_create_namespace("translator")
	-- 	-- vim.api.nvim_buf_add_highlight(translation_bufnr, ns_id, "Title", 0, 0, -1)
	--
	-- 	ui_handles.initialized = true
	-- 	ui_handles.content = ""
	-- elseif header and header ~= "" and header ~= ui_handles.last_header then
	-- 	-- 更新语言信息行
	-- 	vim.api.nvim_buf_set_lines(translation_bufnr, 0, 1, false, { header })
	-- 	ui_handles.last_header = header
	-- end

	-- 追加新内容到缓冲区
	ui_handles.content = (ui_handles.content or "") .. translation

	-- 替换内容部分（从第3行开始）
	vim.api.nvim_buf_set_lines(translation_bufnr, 0, -1, false, vim.split(ui_handles.content, "\n"))

	-- 恢复为只读
	vim.api.nvim_set_option_value("modifiable", false, { buf = translation_bufnr })
	vim.api.nvim_set_option_value("readonly", true, { buf = translation_bufnr })

	-- 如果是流式输出，滚动到底部
	if is_streaming and ui_handles.translation_winnr then
		local line_count = vim.api.nvim_buf_line_count(translation_bufnr)
		vim.api.nvim_win_set_cursor(ui_handles.translation_winnr, { line_count, 0 })
	end
end

-- 不再需要计算高度的函数，因为我们使用固定高度和滚动条
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
