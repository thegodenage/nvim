# dotfiles — Neovim + WezTerm

Personal Neovim configuration. The WezTerm config lives here too (under `wezterm/`) so both
travel together in this repo, but it has to be symlinked into place because WezTerm reads
from `~/.config/wezterm/`, not `~/.config/nvim/wezterm/`.

## Layout

```
~/.config/nvim/                  ← this repo, also Neovim's config root
├── init.lua                     entry point
├── lazy-lock.json               plugin commit pins
├── lua/                         Neovim Lua modules
│   ├── config/                  lazy.nvim bootstrap
│   ├── plugins/                 one plugin per file
│   └── thegodenage/             options + global remaps
├── wezterm/                     WezTerm config (NOT auto-loaded — needs symlink, see below)
│   └── wezterm.lua
├── CHEATSHEET.md                full keymap reference (nvim + wezterm)
└── README.md                    this file
```

## Setup

### Neovim

Cloning to `~/.config/nvim` is all the setup needed; `lazy.nvim` bootstraps itself on first launch.
First-time launch instructions (clean orphan plugins, install LSP servers, etc.) are in
`CHEATSHEET.md` under **First-time setup after this update**.

### WezTerm (requires symlink)

WezTerm looks for its config at `~/.config/wezterm/wezterm.lua`. This repo keeps the WezTerm
config under `wezterm/` so both configs are in one git repo, so you have to symlink it after
cloning:

```sh
# remove any existing real wezterm config first (back it up if you have one)
rm -rf ~/.config/wezterm

# symlink this repo's wezterm dir into place
ln -s ~/.config/nvim/wezterm ~/.config/wezterm
```

Verify:

```sh
ls -la ~/.config/wezterm
# should print: ~/.config/wezterm -> ~/.config/nvim/wezterm
```

Reload WezTerm with `Ctrl+Shift+R` (or restart it) and the new config takes effect.

If you don't use WezTerm, skip this step — nothing in Neovim depends on it.

## Reference

All keymaps (Neovim + WezTerm) and plugin descriptions live in
[`CHEATSHEET.md`](./CHEATSHEET.md). From inside WezTerm you can pop it up at any time with
`Ctrl+A ?`.
