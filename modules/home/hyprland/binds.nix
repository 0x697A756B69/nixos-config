# Hyprland keybinds (Lua config via hl.dsp.*).
{ mainMod, terminal, menu, inline }:

[
  { _args = [ "${mainMod} + Return" (inline "hl.dsp.exec_cmd(\"${terminal}\")") ]; }
  { _args = [ "${mainMod} + R"      (inline "hl.dsp.exec_cmd(\"${menu}\")") ]; }
  { _args = [ "${mainMod} + Q"      (inline "hl.dsp.window.close()") ]; }
  { _args = [ "${mainMod} + M"      (inline "hl.dsp.exit()") ]; }
  { _args = [ "${mainMod} + V"      (inline "hl.dsp.window.float({ action = \"toggle\" })") ]; }
  { _args = [ "${mainMod} + F"      (inline "hl.dsp.window.fullscreen({ action = \"toggle\" })") ]; }

  # Fallback for machines without XF86Audio* keys
  # --- Volume: Fn+F10 down, Fn+F11 up, Fn+F12 mute ---
  { _args = [ "XF86AudioLowerVolume" (inline "hl.dsp.exec_cmd(\"pamixer -d 5\")") ]; }
  { _args = [ "XF86AudioRaiseVolume" (inline "hl.dsp.exec_cmd(\"pamixer -i 5\")") ]; }
  { _args = [ "XF86AudioMute" (inline "hl.dsp.exec_cmd(\"pamixer -t\")") ]; }
  # --- Media: Fn for next/prev/play ---
  { _args = [ "XF86AudioNext" (inline "hl.dsp.exec_cmd(\"playerctl next\")") ]; }
  { _args = [ "XF86AudioPrev" (inline "hl.dsp.exec_cmd(\"playerctl previous\")") ]; }
  { _args = [ "XF86AudioPlay" (inline "hl.dsp.exec_cmd(\"playerctl play-pause\")") ]; }

  # --- Workspaces ---
  { _args = [ "${mainMod} + Z" (inline "hl.dsp.focus({ workspace = \"-1\" })") ]; }
  { _args = [ "${mainMod} + X" (inline "hl.dsp.focus({ workspace = \"+1\" })") ]; }
  { _args = [ "${mainMod} + SHIFT + Z" (inline "hl.dsp.window.move({ workspace = \"-1\" })") ]; }
  { _args = [ "${mainMod} + SHIFT + X" (inline "hl.dsp.window.move({ workspace = \"+1\" })") ]; }

  # --- Toggle floating for all windows ---
  { _args = [ "${mainMod} + D" (inline "hl.dsp.exec_cmd(\"floating_tile_toggle\")") ]; }

  # --- Navigation ---
  { _args = [ "${mainMod} + left"  (inline "hl.dsp.exec_cmd(\"navigate_windows left\")") ]; }
  { _args = [ "${mainMod} + right" (inline "hl.dsp.exec_cmd(\"navigate_windows right\")") ]; }
  { _args = [ "${mainMod} + up"    (inline "hl.dsp.exec_cmd(\"navigate_windows up\")") ]; }
  { _args = [ "${mainMod} + down"  (inline "hl.dsp.exec_cmd(\"navigate_windows down\")") ]; }

  # --- Move tiled ---
  { _args = [ "${mainMod} + ALT + left"  (inline "hl.dsp.exec_cmd(\"move_window_tiled left\")") ]; }
  { _args = [ "${mainMod} + ALT + right" (inline "hl.dsp.exec_cmd(\"move_window_tiled right\")") ]; }
  { _args = [ "${mainMod} + ALT + up"    (inline "hl.dsp.exec_cmd(\"move_window_tiled up\")") ]; }
  { _args = [ "${mainMod} + ALT + down"  (inline "hl.dsp.exec_cmd(\"move_window_tiled down\")") ]; }

  # --- Move floating (repeating) ---
  { _args = [ "${mainMod} + SHIFT + left"  (inline "hl.dsp.exec_cmd(\"move_window left\")")  { repeating = true; } ]; }
  { _args = [ "${mainMod} + SHIFT + right" (inline "hl.dsp.exec_cmd(\"move_window right\")") { repeating = true; } ]; }
  { _args = [ "${mainMod} + SHIFT + up"    (inline "hl.dsp.exec_cmd(\"move_window up\")")    { repeating = true; } ]; }
  { _args = [ "${mainMod} + SHIFT + down"  (inline "hl.dsp.exec_cmd(\"move_window down\")")  { repeating = true; } ]; }

  # --- Resize (repeating) ---
  { _args = [ "${mainMod} + CTRL + left"  (inline "hl.dsp.exec_cmd(\"resize_window left\")")  { repeating = true; } ]; }
  { _args = [ "${mainMod} + CTRL + right" (inline "hl.dsp.exec_cmd(\"resize_window right\")") { repeating = true; } ]; }
  { _args = [ "${mainMod} + CTRL + up"    (inline "hl.dsp.exec_cmd(\"resize_window up\")")    { repeating = true; } ]; }
  { _args = [ "${mainMod} + CTRL + down"  (inline "hl.dsp.exec_cmd(\"resize_window down\")")  { repeating = true; } ]; }

  # --- Wallpaper: restart with the current/persisted choice ---
  { _args = [ "${mainMod} + B" (inline "hl.dsp.exec_cmd(\"wb-wallpaper\")") ]; }
  # --- Wallpaper: open the picker tab in the settings app ---
  { _args = [ "${mainMod} + W" (inline "hl.dsp.exec_cmd(\"wb-settings openTab wallpaper\")") ]; }

  # --- Screenshot (Plasma-style: area + clipboard) ---
  { _args = [ "Print" (inline "hl.dsp.exec_cmd(\"wb-cap area\")") ]; }
  { _args = [ "SHIFT + Print" (inline "hl.dsp.exec_cmd(\"wb-cap screen\")") ]; }
  # --- Video: toggle screen recording ---
  { _args = [ "${mainMod} + SHIFT + R" (inline "hl.dsp.exec_cmd(\"wb-cap record\")") ]; }
]
