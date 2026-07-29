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

local ensure_herdr_script = wezterm.config_dir .. "/ensure-herdr.sh"

-- Always launch in full screen; ensure herdr is installed on first GUI start.
wezterm.on("gui-startup", function(cmd)
  wezterm.run_child_process({ ensure_herdr_script })

  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():toggle_fullscreen()
end)

-- Ensure GUI-launched WezTerm sees Homebrew + common bin paths.
-- Without this, `command -v glow` (and other brew-installed tools) fail to resolve
-- when WezTerm is launched from Spotlight / Dock / Finder.
config.set_environment_variables = {
  PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:" .. (os.getenv("PATH") or ""),
}

config.keys = {
  -- Option+Left/Right: jump whole words (readline ESC-b / ESC-f)
  { key = "LeftArrow",  mods = "OPT", action = act.SendKey({ key = "b", mods = "ALT" }) },
  { key = "RightArrow", mods = "OPT", action = act.SendKey({ key = "f", mods = "ALT" }) },

  -- Option+Backspace: delete the previous word (readline C-w, ASCII 0x17)
  { key = "Backspace", mods = "OPT", action = act.SendKey({ key = "w", mods = "CTRL" }) },
}

return config
