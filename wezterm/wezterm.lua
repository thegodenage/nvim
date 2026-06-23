local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ── Multiplexer plugins ──────────────────────────────────────────────────────
-- Cloned automatically into ~/.local/share/wezterm/plugins on first launch
-- (needs network once). resurrect.wezterm persists workspace/tab/pane layout to
-- disk so sessions survive a restart; smart_workspace_switcher is the fuzzy
-- session picker (lists existing workspaces + zoxide directories).
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

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

-- Render via Metal (WebGpu) instead of the deprecated OpenGL/CGL backend, whose
-- swap_buffers path segfaults during macOS display-reconfiguration events (screen
-- lock / login window after inactivity).
config.front_end = "WebGpu"

-- ── Background image ────────────────────────────────────────────────────────
-- Drop an image named `background.gif` or `background.png` next to this file
-- (nvim/wezterm/) and it is rendered behind everything, heavily dimmed so text
-- stays readable. The check keeps the config valid when no image is present.
-- Note: an animated GIF re-renders every frame, so it costs noticeably more
-- CPU/GPU/battery than a static PNG. Delete background.gif to stop the animation.
local background_image
for _, candidate in ipairs({ "/background.gif", "/background.png" }) do
  local path = wezterm.config_dir .. candidate
  local handle = io.open(path, "r")
  if handle then
    handle:close()
    background_image = path
    break
  end
end
if background_image then
  config.background = {
    {
      source = { File = background_image },
      horizontal_align = "Center",
      vertical_align = "Middle",
      width = "100%",
      height = "100%",
      hsb = { brightness = 0.08 },
    },
    {
      source = { Color = "#1e1e2e" }, -- Catppuccin Mocha base, as a dimming veil
      width = "100%",
      height = "100%",
      opacity = 0.8,
    },
  }
end

-- Use real macOS fullscreen (own Space, menu bar stays hidden on focus change)
-- instead of WezTerm's default non-native "simple" fullscreen.
config.native_macos_fullscreen_mode = true

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
  { key = "phys:H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "phys:J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
  { key = "phys:K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "phys:L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

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
  -- fuzzy session picker: existing workspaces + zoxide-known project dirs
  { key = "s", mods = "LEADER", action = workspace_switcher.switch_workspace() },

  -- restore a saved session from disk (resurrect fuzzy picker)
  {
    key = "phys:R",
    mods = "LEADER|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, "^([^/]+)")
        id = string.match(id, "([^/]+)$")
        id = string.match(id, "(.+)%..+$")
        local opts = {
          window = win:mux_window(),
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        if type == "workspace" then
          local state = resurrect.state_manager.load_state(id, "workspace")
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == "window" then
          local state = resurrect.state_manager.load_state(id, "window")
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == "tab" then
          local state = resurrect.state_manager.load_state(id, "tab")
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end)
    end),
  },

  -- save the current workspace state to disk right now (auto-save also runs)
  {
    key = "w",
    mods = "LEADER",
    action = wezterm.action_callback(function(_, _)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
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
    key = "phys:S",
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

-- ── Multiplexer wiring ───────────────────────────────────────────────────────
workspace_switcher.apply_to_config(config)

-- GUI-launched WezTerm (Spotlight/Dock) doesn't inherit the shell PATH, so point
-- the switcher at the absolute zoxide binary rather than relying on a bare name.
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"

-- Auto-save: persist workspaces/windows/tabs every 5 minutes.
resurrect.state_manager.periodic_save({
  interval_seconds = 300,
  save_workspaces = true,
  save_windows = true,
  save_tabs = true,
})

-- Save the workspace you're leaving when you pick another in the switcher.
wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(_, _, _)
  resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
end)

-- When the switcher creates a workspace, restore its saved layout if one exists.
wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, _, label)
  local ok, state = pcall(resurrect.state_manager.load_state, label, "workspace")
  if ok and state then
    resurrect.workspace_state.restore_workspace(state, {
      window = window:mux_window(),
      relative = true,
      restore_text = true,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    })
  end
end)

return config
