# 🌐 translator.nvim

A powerful AI-powered translation plugin, leveraging OpenAI's GPT models to provide high-quality translations with natural language understanding.

## ✨ Features

- 🤖 Powered by OpenAI's GPT models for accurate and natural translations
- 🌍 Support for multiple languages
- 🔄 Automatic language detection
- 💫 Real-time streaming translation
- 🪟 Beautiful floating window UI
- ⚡ Fast and efficient performance
- ⚙️ Highly customizable

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "doodleEsc/translator.nvim",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("translator").setup({
            -- your configuration comes here
            -- if you want to use default configuration, you can omit this
        })
    end,
}
```

## ⚙️ Configuration

Here's the default configuration with all available options:

````lua
require("translator").setup({
    -- Translation engine configuration
    translate_engine = {
        base_url = "https://api.openai.com/v1",
        api_key = os.getenv("OPENAI_API_KEY"), -- Set your OpenAI API key in environment variable
        model = "gpt-3.5-turbo",
        temperature = 0.8,
        streaming = true, -- Enable streaming translation
    },
    -- Language detection engine configuration
    detect_engine = {
        base_url = "https://api.openai.com/v1",
        api_key = os.getenv("OPENAI_API_KEY"),
        model = "gpt-3.5-turbo",
    },
    -- UI configuration
    ui = {
        width = 0.8, -- Window width (80% of screen)
        height = 0.4, -- Window height (40% of screen)
        border = {
            style = "rounded",
            text = {
                top_source = " Source ",
                top_target = " Translation ",
                top_align = "center",
            },
        },
    },
    -- Translation settings
    proxy = nil, -- Set proxy if needed
    prompt = "Translate the following text from $SOURCE_LANG to $TARGET_LANG, no explanations.:\n```$TEXT\n```",
    source_language = "auto", -- Set to "auto" for automatic detection
    target_language = "zh", -- Default target language
    -- Keymaps configuration
    keymaps = {
        enable = true,
        translate = "<leader>ts", -- Translation shortcut in visual mode
    },
})
````

## 🗣️ Supported Languages

- English (en)
- Chinese (zh)
- Japanese (ja)
- Korean (ko)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Russian (ru)
- Portuguese (pt)
- Dutch (nl)
- Arabic (ar)
- Hindi (hi)

## 🚀 Usage

1. Set your OpenAI API key in your environment:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

2. Select text in visual mode and use one of these methods to translate:
   - Press `<leader>ts` (default keybinding)
   - Run the `:Translate` command

## ⌨️ Commands

| Command      | Mode   | Description             |
| ------------ | ------ | ----------------------- |
| `:Translate` | Visual | Translate selected text |

## ⚡ Keymaps

| Keymap       | Mode   | Description             |
| ------------ | ------ | ----------------------- |
| `<leader>ts` | Visual | Translate selected text |

## 📝 License

MIT
