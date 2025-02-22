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
- [⚙️ Configuration](#️-configuration)
  - [`max_completions`](#max_completions)
  - [`max_attempts`](#max_attempts)
  - [`kind_name`](#kind_name)
  - [`kind_icon`](#kind_icon)
  - [`debounce`](#debounce)
  - [`auto_refresh`](#auto_refresh)
- [🥘 Recipes](#-recipes)
  - [Not Using LazyVim?](#not-using-lazyvim)
  - [With LazyVim copilot extra](#with-lazyvim-copilot-extra)
- [📚 Frequently Asked Questions](#-frequently-asked-questions)
- [🔄 Alternatives and Related Projects](#-alternatives-and-related-projects)
- [🪪 License](#-license)

</details>

## 📋 Requirements

- Neovim >= 0.9.0
- GitHub Copilot LSP Provider (choose one of the following)
  - [copilot.vim][copilot-vim-github] - Official GitHub Copilot Vim/Neovim Plugin
  - [copilot.lua][copilot-lua-github] - Third-party GitHub Copilot written in Lua

## 🌟 Features

1. Developed according to the `blink.cmp` async specification.
2. Automatically detects LSP client on buffer switching, ensuring seamless
   functionality even if the Copilot LSP client isn't attached on the first
   file opening.
3. Supports multiple completion candidates and automatically retries if a
   request fails.
4. Automatically refreshes Copilot suggestion items when the cursor moves.
5. Add debounce to avoid excessive requests to Copilot.
6. Utilizes the latest GitHub Copilot LSP API, resulting in less preprocessing
   and better performance compared to similar plugins.
7. Offers superior performance over copilot.lua with rewritten native LSP
   interaction, even when using the official Vim plugin.
8. Features enhanced preview with smart deindentation formatting.
9. Supports both `copilot.lua` and the official `copilot.vim` as backend LSP providers.
10. Easily register and customize the completion kind and icon.

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
      -- `kind_name` is not set, so the default value is "Copilot"
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
            -- * kind_name, kind_icon, debounce, auto_refresh are default
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
  kind_name = "Copilot",
  kind_icon = "",
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

Specifies the type of completion item to display.

Default: `"Copilot"`

### `kind_icon`

Specifies the icon of completion item to display.

Default: `""`

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

Default: `750`

### `auto_refresh`

Automatically refreshes the completion list when the cursor moves.

> [!NOTE]
> If you enable `backward`, the completion list will be refreshed when the cursor
> moves backward. If you enable `forward`, the completion list will be refreshed
> when the cursor moves forward.

Default: `{ backward = true, forward = true }`

## 🥘 Recipes

Here are some example configuration for using `blink-copilot` with [lazy.nvim][lazy-nvim-github].

### Not Using LazyVim?

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
    for _, event in pairs({ "FileType", "BufUnload", "BufEnter" }) do
      vim.api.nvim_create_autocmd({ event }, {
        group = "github_copilot",
        callback = function()
          vim.fn["copilot#On" .. event]()
        end,
      })
    end
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

### With LazyVim [copilot][lazyvim-copilot-extra] extra

<details>
<summary><code>blink-cmp-copilot</code> ➡️ <code>blink-copilot</code></summary>

```lua
{ import = "lazyvim.plugins.extras.ai.copilot" },
{
  "giuxtaposition/blink-cmp-copilot",
  enabled = false,
},
{
  "saghen/blink.cmp",
  dependencies = { "fang2hou/blink-copilot" },
  opts = {
    sources = {
      providers = {
        copilot = {
          module = "blink-copilot",
        },
      },
    },
  },
}
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
    vim.api.nvim_create_augroup("github_copilot", { clear = true })
    for _, event in pairs({ "FileType", "BufUnload", "BufEnter" }) do
      vim.api.nvim_create_autocmd({ event }, {
        group = "github_copilot",
        callback = function()
          vim.fn["copilot#On" .. event]()
        end,
      })
    end
  end,
}
```

</details>

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
[copilot-vim-github]: https://github.com/github/copilot.vim
[copilot-lua-github]: https://github.com/zbirenbaum/copilot.lua
[lazyvim-copilot-extra]: https://www.lazyvim.org/extras/ai/copilot
[lazy-nvim-github]: https://github.com/folke/lazy.nvim
[blink-cmp-github]: https://github.com/Saghen/blink.cmp
[cmp-copilot-github]: https://github.com/hrsh7th/cmp-copilot
[copilot-cmp-github]: https://github.com/zbirenbaum/copilot-cmp
[blink-cmp-copilot-github]: https://github.com/giuxtaposition/blink-cmp-copilot
