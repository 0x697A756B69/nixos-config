
{ config, pkgs, lib, self, ... }:
{
  options.styling.palette = lib.mkOption {
    type = lib.types.package;
    description = ''
      Material You palette derived from the wallpaper by matugen at build time.
      colors.css, colors.json, colors-matugen.lua, rofi-colors.rasi, kitty.conf, zenChrome.css.
    '';
  };
  config.styling.palette = pkgs.runCommand "desktop-palette" {
    nativeBuildInputs = [ pkgs.matugen pkgs.jq pkgs.ffmpeg ];
  } ''
    set -euo pipefail
    mkdir -p $out
    ffmpeg -y -i ${self}/modules/home/theming/wallpapers/wallpaper_upscaled_2k.mp4 -vf 'scale=512:288' -frames:v 1 frame.png -loglevel error
    matugen image frame.png -m dark --json hex --source-color-index 0 </dev/null > palette.json
    # CSS (waybar + wofi)
    jq -r '
      "@define-color base      " + .colors.surface.dark.color         + ";",
      "@define-color base_alt  " + .colors.surface_variant.dark.color + ";",
      "@define-color text      " + .colors.on_surface.dark.color      + ";",
      "@define-color text_alt  " + .colors.on_surface_variant.dark.color + ";",
      "@define-color accent    " + .colors.primary.dark.color         + ";",
      "@define-color on_accent " + .colors.on_primary.dark.color      + ";",
      "@define-color disabled  " + .colors.outline.dark.color         + ";",
      "@define-color error     " + .colors.error.dark.color           + ";",
      "@define-color border    " + .colors.surface_variant.dark.color + ";",
      "@define-color warning   " + .colors.tertiary.dark.color        + ";"
    ' palette.json > $out/colors.css
    # Translucent variant of the surface color ("frosted glass")
    rgb=$(jq -r '.colors.surface.dark.color' palette.json | tr -d '#')
    hard=$((0x$(printf '%s' "$rgb" | cut -c1-2)))
    soft=$((0x$(printf '%s' "$rgb" | cut -c3-4)))
    deep=$((0x$(printf '%s' "$rgb" | cut -c5-6)))
    printf '@define-color base_glass rgba(%s, %s, %s, 0.45);\n' "$hard" "$soft" "$deep" >> $out/colors.css
    grep -q '@define-color' $out/colors.css
    # Flat JSON, same roles as colors.css, for QML (Quickshell settings app).
    # panel: matugen's own "surface container high" role (Material 3 elevated
    # surface token) rather than surface+alpha — a nearly-opaque card still
    # reads as on-theme instead of a flat dark blend. #f2 prefix = ~0.95 alpha.
    jq -n --slurpfile p palette.json --argjson gr "$hard" --argjson gg "$soft" --argjson gb "$deep" '
      $p[0].colors as $c | {
        base:      $c.surface.dark.color,
        base_alt:  $c.surface_variant.dark.color,
        text:      $c.on_surface.dark.color,
        text_alt:  $c.on_surface_variant.dark.color,
        accent:    $c.primary.dark.color,
        on_accent: $c.on_primary.dark.color,
        disabled:  $c.outline.dark.color,
        error:     $c.error.dark.color,
        border:    $c.surface_variant.dark.color,
        warning:   $c.tertiary.dark.color,
        base_glass: { r: $gr, g: $gg, b: $gb, a: 0.45 },
        panel: ("#f2" + ($c.surface_container_high.dark.color | ltrimstr("#")))
      }
    ' > $out/colors.json
    grep -q '"accent"' $out/colors.json
    # Lua table loaded by theme.lua (nvim)
    jq -r '
      "return {",
      "  foreground = \"" + .colors.on_surface.dark.color         + "\",",
      "  comment    = \"" + .colors.on_surface_variant.dark.color + "\",",
      "  accent     = \"" + .colors.primary.dark.color            + "\",",
      "  on_accent  = \"" + .colors.on_primary.dark.color         + "\",",
      "  surface    = \"" + .colors.surface_variant.dark.color    + "\",",
      "  background = \"" + .colors.surface.dark.color            + "\",",
      "  error      = \"" + .colors.error.dark.color              + "\",",
      "  border     = \"" + .colors.outline.dark.color            + "\",",
      "  secondary  = \"" + .colors.secondary.dark.color          + "\",",
      "  tertiary   = \"" + .colors.tertiary.dark.color           + "\",",
      "}"
    ' palette.json > $out/colors-matugen.lua
    grep -q '^return {' $out/colors-matugen.lua
    # Rofi: .rasi syntax, no @define-color
    jq -r '
      "* {",
      "  base:      " + .colors.surface.dark.color         + ";",
      "  base-alt:  " + .colors.surface_variant.dark.color + ";",
      "  text:      " + .colors.on_surface.dark.color      + ";",
      "  text-alt:  " + .colors.on_surface_variant.dark.color + ";",
      "  accent:    " + .colors.primary.dark.color         + ";",
      "  on-accent: " + .colors.on_primary.dark.color      + ";",
      "  border:    " + .colors.surface_variant.dark.color + ";",
      "  error:     " + .colors.error.dark.color           + ";",
      "  radius:    16px;",
      "}"
    ' palette.json > $out/rofi-colors.rasi
    erb=$(jq -r '.colors.error.dark.color' palette.json | tr -d '#')
    er=$((0x$(printf '%s' "$erb" | cut -c1-2)))
    eg=$((0x$(printf '%s' "$erb" | cut -c3-4)))
    eb=$((0x$(printf '%s' "$erb" | cut -c5-6)))
    sed -i "s/^}/  error-soft: rgba($er, $eg, $eb, 0.18);\n}/" $out/rofi-colors.rasi
    grep -q 'error-soft' $out/rofi-colors.rasi
    # Kitty: background/foreground/cursor + 16 ANSI colors
    jq -r '
      "background            " + .colors.surface_variant.dark.color,
      "foreground            " + .colors.on_surface.dark.color,
      "cursor                " + .colors.primary.dark.color,
      "cursor_text_color     " + .colors.on_primary.dark.color,
      "selection_background  " + .colors.primary.dark.color,
      "selection_foreground  " + .colors.on_primary.dark.color
    ' palette.json > $out/kitty.conf
    printf 'background_opacity 0.40\n' >> $out/kitty.conf
    # Luminance clamp: keeps colors readable on a translucent background.
    jq -r '
      ("0123456789abcdef" as $hex
       | def dv(c): ($hex|index(c)) as $i | if $i == null then error("hex digit") else $i end;
         def h2dec(s): dv(s[0:1])*16 + dv(s[1:2]);
         def hx(v): if v < 16 then "0" + $hex[v:v+1] else ($hex[((v/16)|floor)%16:((v/16)|floor)%16+1] + $hex[v%16:v%16+1]) end;
         .base16 | to_entries | to_entries[]
         | .key as $k
         | (.value.value.dark.color | ltrimstr("#")) as $h
         | (h2dec($h[0:2]) as $r
            | h2dec($h[2:4]) as $g
            | h2dec($h[4:6]) as $b
            | (0.2126*$r + 0.7152*$g + 0.0722*$b) as $raw
            | (if $raw < 60 then 72/$raw elif $raw > 235 then 215/$raw else 1 end) as $f0
            | (255/(if $r > $g and $r > $b then $r elif $g > $b then $g else $b end)) as $cap
            | (if $f0 > $cap then $cap else $f0 end) as $f
            | (($r*$f) | floor) as $nr
            | (($g*$f) | floor) as $ng
            | (($b*$f) | floor) as $nb
            | "color\($k) #\(hx($nr))\(hx($ng))\(hx($nb))"))
    ' palette.json >> $out/kitty.conf
    grep -q '^color15 ' $out/kitty.conf
    # Zen Browser: ''${var} escaped to stay a bash literal, not interpolated by Nix.
    rgba() {
      local h a r g b
      h=$(printf '%s' "$1" | tr -d '#')
      a=$2
      r=$(printf '%d' "$((0x$(printf '%s' "$h" | cut -c1-2)))")
      g=$(printf '%d' "$((0x$(printf '%s' "$h" | cut -c3-4)))")
      b=$(printf '%d' "$((0x$(printf '%s' "$h" | cut -c5-6)))")
      printf 'rgba(%s, %s, %s, %s)' "$r" "$g" "$b" "$a"
    }
    sf=$(jq -r '.colors.surface.dark.color' palette.json)
    sfv=$(jq -r '.colors.surface_variant.dark.color' palette.json)
    onsf=$(jq -r '.colors.on_surface.dark.color' palette.json)
    prim=$(jq -r '.colors.primary.dark.color' palette.json)
    tert=$(jq -r '.colors.tertiary.dark.color' palette.json)
    outl=$(jq -r '.colors.outline.dark.color' palette.json)
    cat > $out/zenChrome.css <<EOF
:root {
  --zen-main-browser-background: $(rgba "$sfv" 0.45);
  --zen-main-browser-background-toolbar: var(--zen-main-browser-background);
  --zen-toolbox-background: $(rgba "$sfv" 0.45);
  --zen-themed-toolbar-bg-transparent: $(rgba "$sfv" 0.45);
  --zen-navigator-toolbox-background: $(rgba "$sfv" 0.45);
  --zen-colors-primary: ''${prim};
  --zen-colors-secondary: ''${prim};
  --zen-colors-tertiary: ''${tert};
  --zen-colors-border: ''${outl};
  --toolbar-bgcolor: ''${sfv};
  --toolbar-color-scheme: dark;
  --urlbar-bgcolor: ''${sf};
  --tab-selected-bgcolor: ''${sfv};
  --lwt-accent-color: ''${sf};
  --lwt-text-color: ''${onsf};
  --in-content-page-background: ''${sf};
  --in-content-page-color: ''${onsf};
}
EOF
    grep -q -- '--zen-colors-primary' $out/zenChrome.css
    # Vesktop (Vencord)
    cat > $out/vesktop.theme.css <<EOF
/**
 * @name Matugen Wallpaper Theme
 * @version 1.0.0
 */
:root {
  --background-primary: ''${sf};
  --background-secondary: ''${sfv};
  --background-secondary-alt: ''${sfv};
  --background-tertiary: ''${sf};
  --background-floating: ''${sfv};
  --background-mobile-primary: ''${sf};
  --background-mobile-secondary: ''${sfv};
  --text-normal: ''${onsf};
  --text-muted: ''${onsf};
  --header-primary: ''${onsf};
  --header-secondary: ''${onsf};
  --interactive-normal: ''${onsf};
  --interactive-hover: ''${onsf};
  --interactive-active: ''${prim};
  --interactive-muted: ''${outl};
  --brand-experiment: ''${prim};
  --brand-experiment-560: ''${prim};
  --channeltextarea-background: ''${sfv};
  --input-background: ''${sfv};
  --scrollbar-thin-thumb: ''${outl};
  --scrollbar-auto-thumb: ''${outl};
  --scrollbar-auto-track: ''${sf};
}
EOF
    grep -q -- '--background-primary' $out/vesktop.theme.css
  '';
}

