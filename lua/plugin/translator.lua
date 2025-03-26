if vim.g.loaded_translator then
	return
end
vim.g.loaded_translator = true

-- 创建用户命令，仅在 visual 模式下可用
vim.api.nvim_create_user_command("Translate", function()
	require("translator").translate()
end, { range = true })

-- 设置默认键位映射，仅针对 visual 模式
vim.api.nvim_set_keymap("v", "<leader>ts", ":Translate<CR>", { noremap = true, silent = true })
