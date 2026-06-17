local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ── Appearance ──────────────────────────────────────────────────────────────
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "JetBrains Mono",
  "Symbols Nerd Font Mono",
  "Menlo",
})
config.font_size = 14
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.window_decorations = "RESIZE"
config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

-- Always launch in full screen.
wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

-- Ensure GUI-launched WezTerm sees Homebrew + common bin paths.
-- Without this, `command -v glow` (and other brew-installed tools) fail to resolve
-- when WezTerm is launched from Spotlight / Dock / Finder.
config.set_environment_variables = {
  PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:" .. (os.getenv("PATH") or ""),
}

-- ── tmux-style leader: Ctrl+A ───────────────────────────────────────────────
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }

config.keys = {
  -- send literal Ctrl+A (when you actually need it in the shell/nvim)
  { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

  -- ── Panes (tmux: splits) ──────────────────────────────────────────────────
  { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER",       action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- pane navigation
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

  -- pane resize (hold Shift)
  { key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
  { key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

  -- pane management
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

  -- ── Tabs (tmux: windows) ──────────────────────────────────────────────────
  { key = "c", mods = "LEADER",       action = act.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER",       action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER",       action = act.ActivateTabRelative(-1) },
  { key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },

  -- tab by number (LEADER + 1..9)
  { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = act.ActivateTab(4) },
  { key = "6", mods = "LEADER", action = act.ActivateTab(5) },
  { key = "7", mods = "LEADER", action = act.ActivateTab(6) },
  { key = "8", mods = "LEADER", action = act.ActivateTab(7) },
  { key = "9", mods = "LEADER", action = act.ActivateTab(8) },

  -- ── Workspaces (tmux: sessions) ───────────────────────────────────────────
  { key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  {
    key = "$",
    mods = "LEADER|SHIFT",
    action = act.PromptInputLine({
      description = "Rename workspace",
      action = wezterm.action_callback(function(window, _, line)
        if line and #line > 0 then
          wezterm.mux.rename_workspace(window:active_workspace(), line)
        end
      end),
    }),
  },
  {
    key = "S",
    mods = "LEADER|SHIFT",
    action = act.PromptInputLine({
      description = "New workspace name",
      action = wezterm.action_callback(function(window, pane, line)
        if line and #line > 0 then
          window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
        end
      end),
    }),
  },

  -- copy mode (tmux: prefix-[ )
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },

  -- reload config (tmux: prefix-r)
  { key = "r", mods = "LEADER", action = act.ReloadConfiguration },

  -- open the nvim+wezterm cheatsheet in a new pane (prefers glow, falls back to less)
  {
    key = "?",
    mods = "LEADER",
    action = act.SplitPane({
      direction = "Right",
      size = { Percent = 50 },
      command = {
        args = {
          "sh",
          "-c",
          'command -v glow >/dev/null 2>&1 && glow -p "$HOME/.config/nvim/CHEATSHEET.md" || less -R "$HOME/.config/nvim/CHEATSHEET.md"',
        },
      },
    }),
  },
}

return config
