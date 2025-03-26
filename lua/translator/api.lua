local M = {}
local config = require("translator.config")
local curl = require("plenary.curl")

-- 构建请求头
local function get_headers()
	return {
		["Content-Type"] = "application/json",
		["Authorization"] = "Bearer " .. config.options.api_key,
	}
end

-- 检测语言
function M.detect_language(text, callback)
	if config.options.source_language ~= "auto" then
		-- 如果不是自动检测，直接返回配置的源语言
		local source_lang = config.options.source_language
		local source_lang_full = config.SUPPORTED_LANGUAGES[source_lang] or "English"
		callback(source_lang, source_lang_full)
		return
	end

	local messages = {
		{
			role = "system",
			content = "You are a language detector. Only return the ISO 639-1 language code of the text, no explanations.",
		},
		{ role = "user", content = text },
	}

	-- local request_opts = {
	-- 	url = config.options.base_url .. "/chat/completions",
	-- 	headers = get_headers(),
	-- 	body = vim.fn.json_encode({
	-- 		model = config.options.model,
	-- 		messages = messages,
	-- 		temperature = 0.3,
	-- 	}),
	-- }

	local url = config.options.base_url .. "/chat/completions"
	local headers = get_headers()
	local body = vim.fn.json_encode({
		model = config.options.model,
		messages = messages,
		temperature = 0.3,
	})

	-- -- 添加代理配置
	-- if config.options.proxy then
	-- 	request_opts.proxy = config.options.proxy
	-- end

	-- curl.post(request_opts, function(response)
	-- 	if response.status ~= 200 then
	-- 		vim.schedule(function()
	-- 			vim.notify("Language detection API error: " .. (response.body or "Unknown error"), vim.log.levels.ERROR)
	-- 		end)
	-- 		callback("en", "English") -- 默认回退到英语
	-- 		return
	-- 	end
	--
	-- 	local result = vim.fn.json_decode(response.body)
	-- 	local detected = result.choices[1].message.content:lower():match("^%s*(.-)%s*$")
	--
	-- 	-- 检查是否是支持的语言，否则默认为英语
	-- 	local source_lang = config.SUPPORTED_LANGUAGES[detected] and detected or "en"
	-- 	local source_lang_full = config.SUPPORTED_LANGUAGES[source_lang]
	--
	-- 	vim.schedule(function()
	-- 		callback(source_lang, source_lang_full)
	-- 	end)
	-- end)

	curl.post(url, {
		headers = headers,
		body = body,
		proxy = config.options.proxy,
		callback = function(response)
			if response.status ~= 200 then
				vim.schedule(function()
					vim.notify("Error detecting language: " .. (response.body or "Unknown error"), vim.log.levels.ERROR)
				end)
				return
			end
			vim.schedule(function()
				local result = vim.fn.json_decode(response.body)
				local detected_language = result.choices[1].message.content:match("^%s*(.-)%s*$")
				callback(detected_language)
			end)
		end,
		on_error = function(error)
			vim.notify("Error detecting language: " .. (error.message or "Unknown error"), vim.log.levels.ERROR)
		end,
	})
end

-- 构建请求体
local function build_request_body(text, source_lang_full)
	local prompt = config.options.prompt
	prompt = prompt:gsub("$SOURCE_LANG", source_lang_full)
	prompt = prompt:gsub("$TARGET_LANG", config.options.target_language_full)
	prompt = prompt:gsub("$TEXT", text)

	return {
		model = config.options.model,
		messages = {
			{ role = "user", content = prompt },
		},
		stream = config.options.streaming,
	}
end

-- 标准翻译（非流式）
function M.translate(text, callback)
	-- 首先检测语言
	M.detect_language(text, function(source_lang_full)
		local body = build_request_body(text, source_lang_full)
		body.stream = false

		local url = config.options.base_url .. "/chat/completions"
		local headers = get_headers()
		-- 将表转换为JSON字符串
		local body_json = vim.fn.json_encode(body)

		curl.post(url, {
			headers = headers,
			body = body_json,
			proxy = config.options.proxy,
			callback = function(response)
				if response.status ~= 200 then
					vim.schedule(function()
						vim.notify(
							"Translation API error: " .. (response.body or "Unknown error"),
							vim.log.levels.ERROR
						)
					end)
					return
				end
				vim.schedule(function()
					local result = vim.fn.json_decode(response.body)
					local translation = result.choices[1].message.content
					callback(translation, source_lang_full)
				end)
			end,
			on_error = function(error)
				vim.notify("Error detecting language: " .. (error.message or "Unknown error"), vim.log.levels.ERROR)
			end,
		})
	end)
end

-- 流式翻译
function M.stream_translate(text, callback)
	-- 首先检测语言
	M.detect_language(text, function(source_lang_full)
		local body = build_request_body(text, source_lang_full)
		body.stream = true

		-- 将表转换为JSON字符串
		local body_json = vim.fn.json_encode(body)

		local url = config.options.base_url .. "/chat/completions"
		local headers = get_headers()

		local translation_buffer = ""

		curl.post(url, {
			headers = headers,
			body = body_json, -- 使用JSON字符串而不是表
			proxy = config.options.proxy,
			-- stream = true,
			stream = function(error, data)
				-- if response.status ~= 200 then
				-- 	vim.schedule(function()
				-- 		vim.notify(
				-- 			"Translation API error: " .. (response.body or "Unknown error"),
				-- 			vim.log.levels.ERROR
				-- 		)
				-- 	end)
				-- 	return
				-- end

				vim.schedule(function()
					-- 处理 SSE 流式响应
					if data == nil then
						return
					end
					local lines = vim.split(data, "\n")
					for _, line in ipairs(lines) do
						if line:match("^data: ") then
							local data = line:sub(7)
							if data ~= "[DONE]" then
								local success, result = pcall(vim.fn.json_decode, data)
								if
									success
									and result
									and result.choices
									and result.choices[1]
									and result.choices[1].delta
								then
									local content = result.choices[1].delta.content
									if content then
										translation_buffer = translation_buffer .. content
										callback(translation_buffer, source_lang_full)
									end
								end
							end
						end
					end
				end)
			end,
			on_error = function(error)
				vim.schedule(function()
					vim.notify("Error in translation: " .. (error.message or "Unknown error"), vim.log.levels.ERROR)
				end)
			end,
		})
	end)
end

-- -- 流式翻译
-- function M.stream_translate(text, callback)
-- 	-- 首先检测语言
-- 	M.detect_language(text, function(source_lang_full)
-- 		local body = build_request_body(text, source_lang_full)
-- 		body.stream = true
--
-- 		local url = config.options.base_url .. "/chat/completions"
-- 		local headers = get_headers()
-- 		-- local body = vim.fn.json_encode(body)
--
-- 		-- local request_opts = {
-- 		-- 	url = config.options.base_url .. "/chat/completions",
-- 		-- 	headers = get_headers(),
-- 		-- 	body = vim.fn.json_encode(body),
-- 		-- }
-- 		--
-- 		-- -- 添加代理配置
-- 		-- if config.options.proxy then
-- 		-- 	request_opts.proxy = config.options.proxy
-- 		-- end
--
-- 		local translation_buffer = ""
--
-- 		-- curl.post(request_opts, {
-- 		-- 	callback = function(response)
-- 		-- 		if response.status ~= 200 then
-- 		-- 			vim.schedule(function()
-- 		-- 				vim.notify(
-- 		-- 					"Translation API error: " .. (response.body or "Unknown error"),
-- 		-- 					vim.log.levels.ERROR
-- 		-- 				)
-- 		-- 			end)
-- 		-- 			return
-- 		-- 		end
-- 		--
-- 		-- 		-- 处理 SSE 流式响应
-- 		-- 		local lines = vim.split(response.body, "\n")
-- 		-- 		for _, line in ipairs(lines) do
-- 		-- 			if line:match("^data: ") then
-- 		-- 				local data = line:sub(7)
-- 		-- 				if data ~= "[DONE]" then
-- 		-- 					local result = vim.fn.json_decode(data)
-- 		-- 					local content = result.choices[1].delta.content
-- 		-- 					if content then
-- 		-- 						translation_buffer = translation_buffer .. content
-- 		-- 						vim.schedule(function()
-- 		-- 							callback(translation_buffer, source_lang_full)
-- 		-- 						end)
-- 		-- 					end
-- 		-- 				end
-- 		-- 			end
-- 		-- 		end
-- 		-- 	end,
-- 		-- 	stream = true,
-- 		-- })
--
-- 		curl.post(url, {
-- 			headers = headers,
-- 			body = body,
-- 			proxy = config.options.proxy,
-- 			callback = function(response)
-- 				print(vim.inspect(response.body))
-- 				if response.status ~= 200 then
-- 					vim.schedule(function()
-- 						vim.notify(
-- 							"Translation API error: " .. (response.body or "Unknown error"),
-- 							vim.log.levels.ERROR
-- 						)
-- 					end)
-- 					return
-- 				end
--
-- 				vim.schedule(function()
-- 					-- 处理 SSE 流式响应
-- 					local lines = vim.split(response.body, "\n")
-- 					for _, line in ipairs(lines) do
-- 						if line:match("^data: ") then
-- 							local data = line:sub(7)
-- 							if data ~= "[DONE]" then
-- 								local result = vim.fn.json_decode(data)
-- 								local content = result.choices[1].delta.content
-- 								if content then
-- 									translation_buffer = translation_buffer .. content
-- 									-- vim.schedule(function()
-- 									callback(translation_buffer, source_lang_full)
-- 									-- end)
-- 								end
-- 							end
-- 						end
-- 					end
-- 				end)
-- 			end,
-- 			on_error = function(error)
-- 				vim.notify("Error detecting language: " .. (error.message or "Unknown error"), vim.log.levels.ERROR)
-- 			end,
-- 		})
-- 	end)
-- end

return M
