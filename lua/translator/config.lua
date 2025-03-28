local M = {}

-- List of supported languages
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
	-- More languages can be added here
}

M.options = {
	-- Translation engine configuration
	translate_engine = {
		base_url = "https://api.openai.com/v1",
		api_key = os.getenv("OPENAI_API_KEY") or "",
		model = "gpt-3.5-turbo",
		temperature = 0.8,
		streaming = true,
	},
	-- Language detection engine configuration
	detect_engine = {
		base_url = "https://api.openai.com/v1",
		api_key = os.getenv("OPENAI_API_KEY") or "",
		model = "gpt-3.5-turbo",
	},
	-- UI configuration
	ui = {
		width = 0.8, -- 屏幕宽度的80%
		height = 0.4, -- 屏幕高度的40%
		border = {
			style = "rounded", -- Available values: "none", "single", "double", "rounded", "solid", "shadow"
			text = {
				top_source = " Source ", -- Title of the source text window
				top_target = " Translation ", -- Title of the translation window
				top_align = "center", -- Title alignment
			},
		},
	},
	-- Top-level configuration
	proxy = nil,
	prompt = "Translate the following text from $SOURCE_LANG to $TARGET_LANG, no explanations.:\n```$TEXT\n```",
	source_language = "auto", -- Default: auto-detect source language
	target_language = "zh", -- Default: translate to Chinese
	-- Keymaps configuration
	keymaps = {
		-- Set to false to disable default keymaps
		enable = true,
		-- Translation shortcut in visual mode
		translate = "<leader>ts",
	},
}

function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", M.options, opts)

	-- Convert language code to full language name
	if M.options.target_language and M.SUPPORTED_LANGUAGES[M.options.target_language] then
		M.options.target_language_full = M.SUPPORTED_LANGUAGES[M.options.target_language]
	else
		M.options.target_language_full = M.SUPPORTED_LANGUAGES["zh"]
		M.options.target_language = "zh"
	end
end

return M
