local M = {}
local config = require("translator.config")
local curl = require("plenary.curl")

-- Build request headers
local function get_headers(type)
	local api_key = type == "detect" and config.options.detect_engine.api_key or config.options.translate_engine.api_key

	return {
		["Content-Type"] = "application/json",
		["Authorization"] = "Bearer " .. api_key,
	}
end

-- Detect language
function M.detect_language(text, callback)
	if config.options.source_language ~= "auto" then
		-- If not auto-detect, return the configured source language directly
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

	local url = config.options.detect_engine.base_url .. "/chat/completions"
	local headers = get_headers("detect")
	local body = vim.fn.json_encode({
		model = config.options.detect_engine.model,
		messages = messages,
		temperature = 0,
	})

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

-- Build request body
local function build_request_body(text, source_lang_full)
	local prompt = config.options.prompt
	prompt = prompt:gsub("$SOURCE_LANG", source_lang_full)
	prompt = prompt:gsub("$TARGET_LANG", config.options.target_language_full)
	prompt = prompt:gsub("$TEXT", text)

	return {
		model = config.options.translate_engine.model,
		messages = {
			{ role = "user", content = prompt },
		},
		stream = config.options.streaming,
		temperature = config.options.translate_engine.temperature,
	}
end

-- Standard translation (non-streaming)
function M.translate(text, callback)
	-- First detect the language
	M.detect_language(text, function(source_lang_full)
		local body = build_request_body(text, source_lang_full)
		-- body.stream = false

		local url = config.options.translate_engine.base_url .. "/chat/completions"
		local headers = get_headers("translate")
		-- Convert table to JSON string
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

-- Streaming translation
function M.stream_translate(text, callback)
	M.detect_language(text, function(source_lang_full)
		local body = build_request_body(text, source_lang_full)
		local body_json = vim.fn.json_encode(body)

		local url = config.options.translate_engine.base_url .. "/chat/completions"
		local headers = get_headers("translate")

		curl.post(url, {
			headers = headers,
			body = body_json,
			proxy = config.options.proxy,
			stream = function(_, data)
				vim.schedule(function()
					-- Handle SSE streaming response
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
										callback(content, source_lang_full)
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

return M
