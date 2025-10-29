<!-- markdownlint-disable no-inline-html -->
<!-- markdownlint-disable first-line-heading -->

<div align="center">

![Completion Sample][title-image]

# blink-copilot

⚙️ Configurable GitHub Copilot [blink.cmp][blink-cmp-github] source

</div>

<details>

<summary><code>Table of Contents</code></summary>

- [📋 Requirements](#-requirements)
- [🌟 Features](#-features)
- [🥘 Recipes](#-recipes)
- [⚙️ Configuration](#️-configuration)
  - [`max_completions`](#max_completions)
  - [`max_attempts`](#max_attempts)
  - [`kind_name`](#kind_name)
  - [`kind_icon`](#kind_icon)
  - [`kind_hl`](#kind_hl)
  - [`debounce`](#debounce)
  - [`auto_refresh`](#auto_refresh)
- [📚 Frequently Asked Questions](#-frequently-asked-questions)
- [🔄 Alternatives and Related Projects](#-alternatives-and-related-projects)
- [🪪 License](#-license)

</details>

## 📋 Requirements

- Neovim >= 0.11.0
- GitHub Copilot LSP Provider (choose one of the following)
  - [Copilot Language Server][copilot-language-server] - Official GitHub Copilot LSP client
  - [copilot.vim][copilot-vim-github] - Official GitHub Copilot Vim/Neovim Plugin
  - [copilot.lua][copilot-lua-github] - Third-party GitHub Copilot written in Lua
  - [copilot-lsp][copilot-lsp-github] - Native GitHub Copilot LSP client support
    - It also provides a better experience for Copilot's NES feature.

## 🌟 Features

1. Compliant with the blink.cmp async specification.
2. Automatically detects the LSP client during buffer switches.
3. Supports multiple completion candidates.
4. Refreshes Copilot suggestion items dynamically as the cursor moves.
5. Implemented entirely in Lua using the latest GitHub Copilot LSP APIs.
6. Offers an improved preview with auto-indentation for completion items.
7. Compatible with both copilot.lua and the official copilot.vim LSP providers.
8. Easily configurable icon and kind settings.

## 🥘 Recipes

Here are some example configuration for using `blink-copilot` with [lazy.nvim][lazy-nvim-github].

<details>
<summary><code>blink-copilot</code> + <code>Copilot Language Server</code></summary>

Sign in to Copilot, or use the :LspCopilotSignIn command from https://github.com/neovim/nvim-lspconfig.

---

**Option 1: Mason-lspconfig**

<details>
<summary>Using <code>mason-lspconfig.nvim</code> (simpler)</summary>



```lua
{
  "williamboman/mason-lspconfig.nvim", --No manual LSP configuration needed
  opts = {
    ensure_installed = { "copilot" },
  },
  dependencies = { "williamboman/mason.nvim" },
},
{
  "saghen/blink.cmp",
  dependencies = { "fang2hou/blink-copilot" },
  opts = {
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          async = true,
        },
      },
    },
  },
},
```

</details>

---

**Option 2: Mason + Custom lspconfig**

<details>
<summary>Using <code>mason.nvim</code> + <code>nvim-lspconfig</code> (more control)</summary>



```lua
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      copilot = {}, -- manual LSP configuration
    },
  },
},
{
  "mason-org/mason.nvim",
  opts = { ensure_installed = { "copilot" } },
},
{
  "saghen/blink.cmp",
  dependencies = { "fang2hou/blink-copilot" },
  opts = {
    sources = {
      default = { "lsp", "path", "snippets", "buffer", "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          async = true,
        },
      },
    },
  },
},
```

</details>

---

</details>

<details>
<summary><code>blink-copilot</code> + <code>zbirenbaum/copilot.lua</code></summary>

```lua
{
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = { enabled = false },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
},
{
  "saghen/blink.cmp",
  optional = true,
  dependencies = { "fang2hou/blink-copilot" },
  opts = {
    sources = {
      default = { "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },
  },
}
```

</details>

<details>
<summary><code>blink-copilot</code> + <code>github/copilot.vim</code></summary>

```lua
{
  "github/copilot.vim",
  cmd = "Copilot",
  event = "BufWinEnter",
  init = function()
    vim.g.copilot_no_maps = true
  end,
  config = function()
    -- Block the normal Copilot suggestions
    vim.api.nvim_create_augroup("github_copilot", { clear = true })
    vim.api.nvim_create_autocmd({ "FileType", "BufUnload" }, {
      group = "github_copilot",
      callback = function(args)
        vim.fn["copilot#On" .. args.event]()
      end,
    })
    vim.fn["copilot#OnFileType"]()
  end,
},
{
  "saghen/blink.cmp",
  dependencies = { "fang2hou/blink-copilot" },
  opts = {
    sources = {
      default = { "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },
  },
}
```

</details>

<details>
<summary><code>blink-copilot</code> + <code>copilotlsp-nvim/copilot-lsp</code></summary>

You can check the [official documentation][copilot-lsp-github].

```lua
{
  "copilotlsp-nvim/copilot-lsp",
  init = function()
    vim.g.copilot_nes_debounce = 500
    vim.lsp.enable("copilot_ls")
    vim.keymap.set("n", "<tab>", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local state = vim.b[bufnr].nes_state
      if state then
        local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
          or (
            require("copilot-lsp.nes").apply_pending_nes()
            and require("copilot-lsp.nes").walk_cursor_end_edit()
          )
        return nil
      else
        return "<C-i>"
      end
    end, { desc = "Accept Copilot NES suggestion", expr = true })
  end,
}
{
  "saghen/blink.cmp",
  dependencies = { "fang2hou/blink-copilot" },
  opts = {
    sources = {
      default = { "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },
    keymap = {
      preset = "super-tab",
      ["<Tab>"] = {
        function(cmp)
          if vim.b[vim.api.nvim_get_current_buf()].nes_state then
            cmp.hide()
            return (
              require("copilot-lsp.nes").apply_pending_nes()
              and require("copilot-lsp.nes").walk_cursor_end_edit()
            )
          end
          if cmp.snippet_active() then
            return cmp.accept()
          else
            return cmp.select_and_accept()
          end
        end,
        "snippet_forward",
        "fallback",
      },
    },
  },
}
```

</details>

### With 💤 LazyVim [copilot][lazyvim-copilot-extra] extra

```lua
-- Import copilot extra (you can also use `:LazyExtras` to install it)
{ import = "lazyvim.plugins.extras.ai.copilot" },
```

<details>
<summary><i>(Optional)</i><code>copilot.lua</code> ➡️ <code>Copilot Language Server</code></summary>

```lua
{
  "zbirenbaum/copilot.lua",
  enabled = false,
},
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- LazyVim Extra disabled it for copilot.lua
      copilot = { enabled = true },
    },
  },
},
{
  "mason-org/mason.nvim",
  opts = { ensure_installed = { "copilot" } },
},
```

</details>

<details>
<summary><i>(Optional)</i><code>copilot.lua</code> ➡️ <code>copilot.vim</code></summary>

```lua
{
  "zbirenbaum/copilot.lua",
  enabled = false,
},
{
  "github/copilot.vim",
  cmd = "Copilot",
  event = "BufWinEnter",
  init = function()
    vim.g.copilot_no_maps = true
  end,
  config = function()
    -- Block the normal Copilot suggestions
    vim.api.nvim_create_autocmd({ "FileType", "BufUnload" }, {
      group = "github_copilot",
      callback = function(args)
        vim.fn["copilot#On" .. args.event]()
      end,
    })
    vim.fn["copilot#OnFileType"]()
  end,
}
```

</details>

## ⚙️ Configuration

`blink-copilot` seamlessly integrates with **both** <u>`blink.cmp` source options</u>
and <u>Neovim plugin configurations</u>. For most users, simply configuring
the options within blink options `sources.provider.copilot.opts` is sufficient.

<details>

<summary><i>Explore the configuration in detail</i></summary>

```lua
{
  "saghen/blink.cmp",
  optional = true,
  dependencies = {
    "fang2hou/blink-copilot",
    opts = {
      max_completions = 1,  -- Global default for max completions
      max_attempts = 2,     -- Global default for max attempts
    }
  },
  opts = {
    sources = {
      default = { "copilot" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
          opts = {
            -- Local options override global ones
            max_completions = 3,  -- Override global max_completions

            -- Final settings:
            -- * max_completions = 3
            -- * max_attempts = 2
            -- * all other options are default
          }
        },
      },
    },
  },
}
```

</details>

---

Here is the default configuration for `blink-copilot`:

```lua
{
  max_completions = 3,
  max_attempts = 4,
  kind_name = "Copilot", ---@type string | false
  kind_icon = " ", ---@type string | false
  kind_hl = false, ---@type string | false
  debounce = 200, ---@type integer | false
  auto_refresh = {
    backward = true,
    forward = true,
  },
}
```

### `max_completions`

Maximum number of completions to show.

> [!NOTE]
> Sometimes Copilot do not provide any completions, even you set `max_completions`
> to a large number. This is a limitation of Copilot itself, not the plugin.

Default: `3`

### `max_attempts`

Maximum number of attempts to fetch completions.

> [!NOTE]
> Each attempt will fetch 0 ~ 10 completions. Considering the possibility of failure,
> it is generally recommended to set it to `max_completions+1`.

Default: `4`

### `kind_name`

Specifies the **type** of completion item to display. Some distros may
automatically set icon from the `kind_name`.

Set to `false` to disable the `kind_name` in completion items.

Default: `"Copilot"`

### `kind_icon`

Specifies the **icon** of completion item to display.

Set to `false` to disable the `kind_icon` in completion items.

Default: `" "` (![default-icon][copilot-icon-image])

### `kind_hl`

Specifies the **highlight group** of completion item to display.

Set to `false` to disable the `kind_hl` in completion items.

Default: `false`

### `debounce`

> [!NOTE]
> Debounce is a feature that limits the number of requests sent to Copilot.  
> You can customize the debounce time in milliseconds or set it to `false` to
> disable it.

<!-- markdownlint-disable no-blank-blockquote -->

> [!IMPORTANT]
> If you disable debounce and enable `auto_refresh`, the copilot suggestion
> items will be refreshed every time the cursor moves.  
> Excessive refreshing may temporarily block your Copilot.

Default: `200`

### `auto_refresh`

Automatically refreshes the completion list when the cursor moves.

> [!NOTE]
> If you enable `backward`, the completion list will be refreshed when the cursor
> moves backward. If you enable `forward`, the completion list will be refreshed
> when the cursor moves forward.

Default: `{ backward = true, forward = true }`

## 📚 Frequently Asked Questions

> The number of completions does not match my settings.

This is because the number of completions provided by Copilot is not fixed.
The `max_completions` setting is only an upper limit, and the actual number of
completions may be less than this value.

> What's the difference between `blink-copilot` and `blink-cmp-copilot`?

- Completion Preview is now correctly deindented.
- Support both `copilot.lua` and `copilot.vim` as a backend.
- Support multiple completions, and it is configurable.
- LSP interaction no longer relies on `copilot.lua`, ensuring improved
  performance and compliance with the latest official LSP API specifications.
- Auto refresh copilot suggestion items when cursor moves.

> The completion isn't working after restarting Copilot. What should I do?

The Copilot plugin doesn't automatically attach the new LSP client to buffers.
To resolve this, manually reopen your current buffer to attach the LSP client.
`blink-copilot` will automatically detect the new client and resume completions.

> Why aren't blink completions showing up?

Blink intentionally pauses completions during macro recording.
If you see `recording @x` in your statusline, press `q` to stop recording.

## 🔄 Alternatives and Related Projects

- [hrsh7th/cmp-copilot][cmp-copilot-github] -
  The copilot.vim source for `nvim-cmp`.
- [zbirenbaum/copilot-cmp][copilot-cmp-github] -
  The copilot.lua source for `nvim-cmp`.
- [giuxtaposition/blink-cmp-copilot][blink-cmp-copilot-github] -
  The copilot.lua source for `blink.cmp`.

## 🪪 License

MIT

<!-- LINKS -->

[title-image]: https://github.com/user-attachments/assets/dbe4dee4-811f-4f46-be89-4d58dfea9433
[copilot-icon-image]: https://github.com/user-attachments/assets/06330b50-2386-4fc1-8dbd-8040ec4cb2df
[copilot-language-server]: https://github.com/github/copilot-language-server-release
[copilot-vim-github]: https://github.com/github/copilot.vim
[copilot-lua-github]: https://github.com/zbirenbaum/copilot.lua
[copilot-lsp-github]: https://github.com/copilotlsp-nvim/copilot-lsp
[lazyvim-copilot-extra]: https://www.lazyvim.org/extras/ai/copilot
[lazy-nvim-github]: https://github.com/folke/lazy.nvim
[blink-cmp-github]: https://github.com/Saghen/blink.cmp
[cmp-copilot-github]: https://github.com/hrsh7th/cmp-copilot
[copilot-cmp-github]: https://github.com/zbirenbaum/copilot-cmp
[blink-cmp-copilot-github]: https://github.com/giuxtaposition/blink-cmp-copilot
