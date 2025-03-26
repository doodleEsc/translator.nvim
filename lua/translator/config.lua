local M = {}

-- 支持的语言列表
M.SUPPORTED_LANGUAGES = {
	auto = "Auto",
	en = "English",
	zh = "Chinese",
	ja = "Japanese",
	ko = "Korean",
	es = "Spanish",
	fr = "French",
	de = "German",
	it = "Italian",
	ru = "Russian",
	pt = "Portuguese",
	nl = "Dutch",
	ar = "Arabic",
	hi = "Hindi",
	-- 可以继续添加更多语言
}

M.options = {
	base_url = "https://api.openai.com/v1",
	api_key = os.getenv("OPENAI_API_KEY") or "",
	model = "gpt-3.5-turbo",
	proxy = nil,
	window_width = 80,
	streaming = true,
	prompt = "Translate the following text from $SOURCE_LANG to $TARGET_LANG:\n\n$TEXT",
	source_language = "auto", -- 默认自动检测源语言
	target_language = "zh", -- 默认翻译目标语言为中文
}

function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", M.options, opts)

	-- 将语言代码转换为完整语言名称
	if M.options.target_language and M.SUPPORTED_LANGUAGES[M.options.target_language] then
		M.options.target_language_full = M.SUPPORTED_LANGUAGES[M.options.target_language]
	else
		M.options.target_language_full = M.SUPPORTED_LANGUAGES["zh"]
		M.options.target_language = "zh"
	end
end

return M
