# Neovim config — modernization summary

Updated 2026-06-17. Target: Neovim 0.11+.

---

## First-time setup after this update

Old plugins are still in `lazy-lock.json` from the previous config — they will become orphans. The new LSP/completion stack needs installing. Run, in order:

1. **Open Neovim.** Expect errors on first launch — that's normal, `lazy.nvim` hasn't synced yet.
2. `:Lazy clean` — removes the orphaned plugins (`lsp-zero.nvim`, `nvim-cmp`, `cmp-nvim-lsp`, and any others not in the new spec).
3. `:Lazy sync` — installs new plugins (`blink.cmp`, `conform.nvim`, `gitsigns.nvim`, `lualine.nvim`, `which-key.nvim`, `mini.pairs`, `mini.surround`, `telescope-fzf-native`, `telescope-ui-select`, `nvim-lint`, `harpoon` (harpoon2 branch), `bufferline.nvim`).
4. **Restart Neovim.**
5. `:Mason` — confirm language servers install. `mason-lspconfig` will auto-install the list below; if any fail, install manually with `:MasonInstall <name>`. New servers added: `pyright`, `ruff`, `ruby-lsp`, `marksman`, `lua-language-server`.
6. `:TSUpdate` — refresh tree-sitter parsers (newly added: `python`, `ruby`, `markdown`, `markdown_inline`, `tsx`, `css`, `json5`, `toml`, `gomod`, `gosum`, `gowork`, `gotmpl`, `dockerfile`, `gitignore`, `gitcommit`, `diff`, `regex`).
7. **External tools you need on `$PATH`** (Mason does not handle these): `stylua`, `prettier`, `goimports`, `gofmt`. Most are likely already installed via your existing toolchain. `prettier` can be installed via `:MasonInstall prettier` if you want Mason to manage it — but conform doesn't auto-use the Mason path unless you adjust `$PATH`.

After those steps your config is current.

---

## What changed at the plugin level

### Removed
- **`lsp-zero.nvim`** — abandoned. Replaced by Neovim 0.11's native `vim.lsp.config()` / `vim.lsp.enable()` + `nvim-lspconfig` defaults.
- **`nvim-cmp`** + **`cmp-nvim-lsp`** — replaced by `blink.cmp` (single plugin, Rust fuzzy matcher, faster, supplies LSP capabilities itself).
- **`harpoon.lua`** — file deleted; was 100% commented out.

### Rewritten
- **`lsp.lua`** — uses `mason-lspconfig` 2.x's new API (`automatic_enable = true`, no more `handlers`). Per-server config goes through `vim.lsp.config('name', {...})`. One `LspAttach` autocmd, one place. Diagnostics styled with `vim.diagnostic.config`.
- **`treesitter.lua`** — explicitly pinned to `branch = "master"` (the `main` branch has a different API and is mid-migration). Expanded parser list.
- **`telescope.lua`** — fixed the malformed line, added `telescope-fzf-native` (fast fuzzy) and `telescope-ui-select` (replaces `vim.ui.select`, so LSP code actions get a nice picker).

### Added
- **`blink.cmp`** (`cmp.lua`) — completion.
- **`conform.nvim`** (`conform.lua`) — formatter manager; format-on-save lives here, not in LSP.
- **`nvim-lint`** (`lint.lua`) — linter scaffolding (no linters enabled by default; ruff diagnostics come from the ruff LSP).
- **`gitsigns.nvim`** (`gitsigns.lua`) — gutter signs, hunk navigation, blame.
- **`lualine.nvim`** (`lualine.lua`) — statusline.
- **`which-key.nvim`** (`whichkey.lua`) — pops up a menu when you pause mid-keymap. Great for rediscovering what you forgot.
- **`mini.pairs`** + **`mini.surround`** (`mini.lua`) — autopairs and surround.
- **`harpoon`** (`harpoon.lua`) — pin and jump to 1–5 files with one keystroke.
- **`bufferline.nvim`** (`bufferline.lua`) — buffer tabs across the top of the editor.

### Cleanup of `init.lua` / `remap.lua`
- Treewalker keymaps moved into `plugins/treewalker.lua` (where they belong).
- Removed duplicated `signcolumn`, `relativenumber`, and the LSP format-on-save (conform handles it now).
- Added `ignorecase`/`smartcase`, `splitright`/`splitbelow` (small QoL).
- Added `vim.g.loaded_netrw*` guards above the requires so nvim-tree wins cleanly.

---

## Language servers now configured

Installed automatically via Mason:

| Server | Languages |
|---|---|
| `lua_ls` | Lua (knows about `vim` global) |
| `gopls` | Go |
| `biome` | JS, TS, JSX, TSX, JSON, JSONC |
| `helm_ls` | Helm |
| `templ` | Templ |
| `html` | HTML, Templ |
| `tailwindcss` | HTML, Templ, JSX, TSX, CSS |
| `pyright` | Python (types) |
| `ruff` | Python (lint + code actions) |
| `ruby_lsp` | Ruby |
| `marksman` | Markdown |

---

## Formatting

Formatting is owned by `conform.nvim`, not the LSP. Format-on-save runs with a 1s timeout and falls back to LSP formatting if no conform formatter matches.

| Filetype | Formatter chain |
|---|---|
| Lua | `stylua` |
| Go | `goimports` → `gofmt` |
| Python | `ruff_organize_imports` → `ruff_format` |
| JS / TS / JSX / TSX / JSON / JSONC | `biome` |
| HTML / CSS / YAML / Markdown | `prettier` |
| Ruby | (commented out — flip `rubocop` on in `conform.lua` if you want it) |

**Disabling format-on-save**:
- `:FormatDisable` — globally for the session
- `:FormatDisable!` — just for the current buffer
- `:FormatEnable` — turn it back on

---

## Keymap reference

`<leader>` is `<Space>`.

### Files & search (Telescope)
| Keys | Action |
|---|---|
| `<leader>pf` | Find files |
| `<C-p>` | Find git-tracked files |
| `<leader>pb` | Buffers |
| `<leader>pt` | Treesitter symbols |
| `<leader>pg` | Live grep |
| `<leader>ps` | Grep by prompt |
| `<leader>pws` | Grep word under cursor |
| `<leader>pWs` | Grep WORD under cursor |
| `<leader>pd` | Diagnostics picker |
| `<leader>pk` | Keymap picker |
| `<leader>pr` | Resume last picker |
| `<leader>vh` | Help tags |

### File tree
| Keys | Action |
|---|---|
| `<leader>pv` | Focus nvim-tree |

### Harpoon — pinned files
| Keys | Action |
|---|---|
| `<leader>a` | Add current file to the harpoon list |
| `<C-e>` | Toggle the harpoon quick-menu (lets you edit/reorder the list) |
| `<leader>1` … `<leader>5` | Jump to harpoon slot 1–5 |
| `<leader>hn` / `<leader>hp` | Cycle next / previous in the harpoon list |

How to use: open the few files you're working on, press `<leader>a` in each to pin them. Then `<leader>1`, `<leader>2`, … to jump between them. When the task changes, open the menu (`<C-e>`) and edit the list (delete lines, reorder). Harpoon persists per project automatically.

**Note on conflicts:** `<C-e>` overrides vim's default "scroll one line down". The trade is worth it once you use harpoon.

### Bufferline — buffer tabs across the top
| Keys | Action |
|---|---|
| `<S-h>` / `<S-l>` | Cycle to prev / next buffer |
| `[b` / `]b` | Same — prev / next buffer (alternative) |
| `<leader>bd` | Close current buffer |
| `<leader>bp` | Pin / unpin current buffer (stays leftmost) |
| `<leader>bo` | Close all other buffers |
| `<leader>bP` | Close all unpinned buffers |

How to use: bufferline puts a strip across the top showing every open buffer (with diagnostics indicators). You can see at a glance what's open. `<S-h>`/`<S-l>` is the fast cycle. Use bufferline for *all* your open buffers; use harpoon for the *active set* you're bouncing between. They complement each other.

**Note on conflicts:** `<S-h>` and `<S-l>` override vim defaults (`H` = top of screen, `L` = bottom of screen). Standard trade-off in 2026 nvim configs.

### LSP (active when an LSP attaches to the buffer)
| Keys | Action |
|---|---|
| `K` | Hover docs |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `go` | Go to type definition |
| `gr` | References |
| `gs` | Signature help |
| `<F2>` | Rename symbol |
| `<F3>` | Format buffer (LSP, async) |
| `<F4>` | Code action |
| `<leader>e` | Diagnostic float |
| `[d` / `]d` | Prev / next diagnostic |

### Formatting (conform)
| Keys | Action |
|---|---|
| `<leader>f` | Format buffer (or selection in visual mode) |

### Completion (blink.cmp, insert mode)
| Keys | Action |
|---|---|
| `<C-Space>` | Show / toggle docs |
| `<Tab>` / `<S-Tab>` | Next / prev item |
| `<C-n>` / `<C-p>` | Next / prev item |
| `<C-u>` / `<C-d>` | Scroll docs up / down |
| `<CR>` | Accept |
| `<C-e>` | Dismiss |

### Tree navigation (treewalker)
| Keys | Action |
|---|---|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Walk the syntax tree left/down/up/right |

### Trouble (diagnostics UI)
| Keys | Action |
|---|---|
| `<leader>xx` | Diagnostics |
| `<leader>xX` | Buffer diagnostics |
| `<leader>cs` | Symbols |
| `<leader>cl` | LSP refs/defs panel |
| `<leader>xL` | Location list |
| `<leader>xQ` | Quickfix list |

### Git (fugitive)
| Keys | Action |
|---|---|
| `<leader>gs` | `:Git` status |

### Git hunks (gitsigns)
| Keys | Action |
|---|---|
| `]c` / `[c` | Next / prev hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame current line (full) |
| `<leader>hd` | Diff this buffer |
| `<leader>ht` | Toggle inline blame |

### Surround (mini.surround)
| Keys | Action |
|---|---|
| `sa{motion}{char}` | Add surrounding (e.g. `saiw"` quotes a word) |
| `sd{char}` | Delete surrounding |
| `sr{old}{new}` | Replace surrounding |
| `sf{char}` / `sF{char}` | Find surrounding right / left |
| `sh{char}` | Highlight surrounding |

### Treesitter incremental selection
| Keys | Action |
|---|---|
| `<C-Space>` (normal) | Start / expand selection |
| `<BS>` (visual) | Shrink selection |

### Undo
| Keys | Action |
|---|---|
| `<leader>u` | Toggle undotree |

### Discoverability
| Keys | Action |
|---|---|
| `<leader>?` | which-key: show buffer-local keymaps |
| (pause after `<leader>`) | which-key auto-pops |

---

## Files in this config

```
~/.config/nvim/
├── init.lua                     entry point — sets netrw guards, requires config + remap
├── lazy-lock.json               plugin commit pins (auto-managed)
├── lazyvim.json                 lazy.nvim's news state (auto-managed)
├── .luarc.json                  lua_ls workspace config
├── .stylua.toml                 stylua formatting config
├── CHEATSHEET.md                this file
└── lua/
    ├── config/lazy.lua          bootstraps lazy.nvim
    ├── thegodenage/
    │   ├── init.lua             requires remap
    │   └── remap.lua            options + global mappings
    └── plugins/                 one plugin per file
        ├── bufferline.lua       buffer tab bar
        ├── cmp.lua              blink.cmp
        ├── colorscheme.lua      catppuccin
        ├── conform.lua          formatters + format-on-save
        ├── gitsigns.lua         git gutter signs + hunk nav
        ├── harpoon.lua          pin/jump to favourite files
        ├── icons.lua            nvim-web-devicons
        ├── lint.lua             nvim-lint (scaffolding, no linters enabled)
        ├── lsp.lua              LSP (mason + lspconfig + vim.lsp.config)
        ├── lualine.lua          statusline
        ├── mini.lua             mini.pairs + mini.surround
        ├── nvimtree.lua         file tree
        ├── telescope.lua        fuzzy finder
        ├── treesitter.lua       syntax + indentation
        ├── treewalker.lua       structural navigation
        ├── trouble.lua          diagnostics UI
        ├── undotree.lua         undo tree
        ├── vimfugitive.lua      git
        └── whichkey.lua         keymap discovery
```

---

## Known things that need your attention

1. **External binaries on `$PATH`:** `stylua`, `prettier`, `goimports`, `gofmt`. If a formatter doesn't run, check `:ConformInfo` to see what's wired up and where it's looking.
2. **Ruby formatting** is commented out in `conform.lua` because your global instructions say Ruby commands run inside Docker. Uncomment the `ruby = { "rubocop" }` line if you want local rubocop.
3. **Treesitter** is pinned to the `master` branch. The `main` branch migration is a separate effort — flag it when you want to do it.
4. **`vim.opt.hlsearch = false`** is preserved from the old config. Toggle in `remap.lua` if you'd rather see search hits highlighted.
5. **No snippets** are wired up (`friendly-snippets`, `LuaSnip` not installed). Add them if you find yourself wanting expansions.

---

# WezTerm — tmux-style workflow

Config lives at `~/.config/wezterm/wezterm.lua`. Reload after edits with `LEADER r` (or restart WezTerm).

## The mental model

| WezTerm name | tmux name | What it is |
|---|---|---|
| pane | pane | A split inside one tab |
| tab | window | A row of one-or-more panes |
| workspace | session | A named group of tabs (think "project") |

## The leader key

The leader is **`Ctrl+A`** (exactly like a default tmux config). You press leader, release, then press the next key. So "leader, then `c`" means: `Ctrl+A`, release, `c`.

If you actually need to send a literal `Ctrl+A` to whatever's running in the pane (e.g. start-of-line in bash), press it twice: `Ctrl+A Ctrl+A`.

## All keybindings

### Panes (splits inside a tab)
| Keys | Action |
|---|---|
| `LEADER \|` (i.e. Ctrl+A then Shift+\|) | Split horizontally (new pane to the right) |
| `LEADER -` | Split vertically (new pane below) |
| `LEADER h` / `j` / `k` / `l` | Move focus left / down / up / right between panes |
| `LEADER H` / `J` / `K` / `L` | Resize the current pane in that direction (by 5 cells) |
| `LEADER z` | Zoom (toggle pane full-screen within the tab) |
| `LEADER x` | Close current pane (with confirmation) |

### Tabs (multiple terminals in one window)
| Keys | Action |
|---|---|
| `LEADER c` | Create a new tab |
| `LEADER n` | Next tab |
| `LEADER p` | Previous tab |
| `LEADER 1` … `LEADER 9` | Jump to tab N |
| `LEADER &` (Shift+7) | Close current tab (with confirmation) |

### Workspaces (tmux sessions)
| Keys | Action |
|---|---|
| `LEADER s` | Fuzzy switcher across all existing workspaces |
| `LEADER S` (Shift+s) | Create / switch to a new workspace by name |
| `LEADER $` (Shift+4) | Rename the current workspace |

### Other
| Keys | Action |
|---|---|
| `LEADER [` | Enter copy mode (scroll + select with vim motions; `q` exits) |
| `LEADER r` | Reload the WezTerm config |
| `LEADER ?` | Open this cheatsheet in a new pane (right-half split). Uses `glow` if installed, otherwise `less`. Close with `LEADER x` or just `q` in `less`. |
| `LEADER Ctrl+a` | Send a literal `Ctrl+A` to the pane |

## How to actually work with this

**Starting a session for a project** (replacing `tmux new -s myproj`):
1. `LEADER S` → type "myproj" → Enter. You're now in a workspace called "myproj".
2. `LEADER -` to split off a pane for your shell, `LEADER |` to split off another for tests/logs.
3. `LEADER c` if you want more tabs (e.g. one tab for editing, one for running tools).

**Switching between projects** (replacing `tmux switch-client`):
- `LEADER s` opens the fuzzy workspace switcher. Type a few letters, press Enter.

**Detach/reattach (the tmux killer feature):**
- WezTerm doesn't have tmux's daemon-by-default model. Closing the WezTerm window kills its workspaces.
- For survive-across-window-close: run `wezterm-mux-server` once (it daemonizes), then start WezTerm clients that attach to it.
- For survive-across-reboot: install the `resurrect.wezterm` plugin (saves workspace layouts to disk). Not configured here; add when you actually need it.

**Quick reference for muscle memory if you're coming from tmux:**

| What you did in tmux | What you do in WezTerm |
|---|---|
| `prefix c` | `LEADER c` ✓ same |
| `prefix \|` / `prefix %` | `LEADER \|` (h-split), `LEADER -` (v-split) |
| `prefix hjkl` (with vim-tmux-navigator) | `LEADER hjkl` ✓ same |
| `prefix n` / `prefix p` | `LEADER n` / `LEADER p` ✓ same |
| `prefix 1-9` | `LEADER 1-9` ✓ same |
| `prefix z` | `LEADER z` ✓ same |
| `prefix s` (session list) | `LEADER s` ✓ same |
| `prefix $` (rename session) | `LEADER $` ✓ same |
| `prefix [` (copy mode) | `LEADER [` ✓ same |
| `prefix d` (detach) | Just close the window (no detach in default WezTerm) |
| `prefix r` (reload) | `LEADER r` ✓ same |
| `prefix &` (kill window) | `LEADER &` ✓ same |
| `prefix x` (kill pane) | `LEADER x` ✓ same |

If something doesn't behave: `LEADER r` to reload, or open WezTerm's debug overlay with `Ctrl+Shift+L`.

