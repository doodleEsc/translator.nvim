local M = {}
local config = require("translator.config")

-- 创建浮动窗口
function M.create_floating_window(source_text)
	local width = config.options.window_width
	local height = M.calculate_height(source_text, width)

	-- 窗口总高度 = 原文高度 + 译文高度(初始为2) + 分隔线(1) + 边框(2) + 语言信息行(1)
	local total_height = height + 2 + 1 + 2 + 1

	-- 计算窗口位置
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - total_height) / 2)

	-- 创建缓冲区
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- 设置窗口选项
	local opts = {
		relative = "editor",
		width = width,
		height = total_height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	}

	-- 创建窗口
	local winnr = vim.api.nvim_open_win(bufnr, false, opts)

	-- -- 设置缓冲区选项
	-- vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	-- vim.api.nvim_buf_set_option(bufnr, "filetype", "translator")
	--
	-- -- 设置窗口选项
	-- vim.api.nvim_win_set_option(winnr, "wrap", true)
	-- vim.api.nvim_win_set_option(winnr, "cursorline", false)

	-- 设置缓冲区选项
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].filetype = "translator"

	-- 设置窗口选项
	vim.wo[winnr].wrap = true
	vim.wo[winnr].cursorline = false

	-- 填充内容
	local lines = {}
	local source_lines = vim.split(source_text, "\n")

	-- 添加原文
	vim.list_extend(lines, source_lines)

	-- 添加分隔线
	table.insert(lines, string.rep("─", width))

	-- 添加语言信息行
	table.insert(lines, "Detecting language...")

	-- 添加翻译占位符
	table.insert(lines, "翻译中...")

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- 设置分隔线高亮
	local ns_id = vim.api.nvim_create_namespace("translator")
	vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Comment", #source_lines, 0, -1)

	-- 设置语言信息行高亮
	vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Title", #source_lines + 1, 0, -1)

	-- 记录原文行数，用于后续更新翻译
	vim.api.nvim_buf_set_var(bufnr, "source_lines_count", #source_lines)

	-- 添加关闭窗口的键位映射
	vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })

	return bufnr, winnr
end

-- 更新翻译内容
function M.update_translation(bufnr, translation, header, is_streaming)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local source_lines_count = vim.api.nvim_buf_get_var(bufnr, "source_lines_count")
	local separator_line = source_lines_count

	-- 更新语言信息行
	if header and header ~= "" then
		vim.api.nvim_buf_set_lines(bufnr, separator_line + 1, separator_line + 2, false, { header })
	end

	-- 清除旧的翻译内容
	vim.api.nvim_buf_set_lines(bufnr, separator_line + 2, -1, false, {})

	-- 添加新的翻译内容
	local translation_lines = vim.split(translation, "\n")
	vim.api.nvim_buf_set_lines(bufnr, separator_line + 2, -1, false, translation_lines)

	-- 如果是流式输出，需要调整窗口高度
	if is_streaming then
		local winnr = vim.fn.bufwinid(bufnr)
		if winnr ~= -1 then
			local width = config.options.window_width
			local source_height = M.calculate_height(
				table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, source_lines_count, false), "\n"),
				width
			)
			local translation_height = M.calculate_height(translation, width)

			-- 窗口总高度 = 原文高度 + 译文高度 + 分隔线(1) + 边框(2) + 语言信息行(1)
			local total_height = source_height + translation_height + 1 + 2 + (header ~= "" and 1 or 0)

			-- 更新窗口高度
			local col = math.floor((vim.o.columns - width) / 2)
			local row = math.floor((vim.o.lines - total_height) / 2)

			vim.api.nvim_win_set_config(winnr, {
				relative = "editor",
				width = width,
				height = total_height,
				col = col,
				row = row,
			})
		end
	end
end

-- 计算文本在给定宽度下的高度
function M.calculate_height(text, width)
	local lines = vim.split(text, "\n")
	local height = 0

	for _, line in ipairs(lines) do
		-- 计算每行文本在给定宽度下占用的行数
		local line_length = vim.fn.strdisplaywidth(line)
		local line_height = math.ceil(line_length / width)
		height = height + math.max(1, line_height)
	end

	return height
end

return M
