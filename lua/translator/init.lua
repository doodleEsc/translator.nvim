local M = {}
local api = require("translator.api")
local ui = require("translator.ui")
local config = require("translator.config")

function M.setup(opts)
	config.setup(opts)
	-- 创建用户命令，仅在 visual 模式下可用
	vim.api.nvim_create_user_command("Translate", function()
		require("translator").translate()
	end, { range = true })

	-- 设置默认键位映射，仅针对 visual 模式
	vim.api.nvim_set_keymap("v", "<leader>ts", ":Translate<CR>", { noremap = true, silent = true })
end

function M.translate()
	-- 获取选中的文本
	local text = M.get_visual_selection()
	if not text or text == "" then
		vim.notify("No text selected", vim.log.levels.ERROR)
		return
	end

	-- 显示浮动窗口并展示原文
	-- local bufnr, winnr = ui.create_floating_window(text)
	local ui_handler = ui.create_floating_window(text)

	-- 根据配置决定是否使用流式输出
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

-- 获取视觉模式下选中的文本
function M.get_visual_selection()
	local _, start_line, start_col, _ = unpack(vim.fn.getpos("'<"))
	local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))

	-- 处理选择模式是 V-LINE 的情况
	if start_line == end_line and start_col == end_col then
		local line = vim.fn.getline(".")
		return line
	end

	local lines = vim.fn.getline(start_line, end_line)

	if #lines == 0 then
		return ""
	end

	-- 处理第一行和最后一行的部分选择
	lines[1] = string.sub(lines[1], start_col)
	lines[#lines] = string.sub(lines[#lines], 1, end_col)

	return table.concat(lines, "\n")
end

return M
