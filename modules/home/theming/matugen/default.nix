{ config, pkgs, lib, ... }:
let
  # Same ffmpeg+matugen+jq pipeline that used to run once at Nix build time
  # against a hardcoded wallpaper — now a runtime script taking any image or
  # video path, so the wallpaper switcher (Quickshell settings app) can
  # re-theme without a rebuild. ffmpeg's `-frames:v 1` grabs a single frame
  # whether the input is a video or already a still image, so no branching
  # on file type is needed.
  themeApply = pkgs.writeShellScriptBin "theme-apply" ''
    set -euo pipefail
    input="$1"
    outdir="$HOME/.cache/theming/current"
    mkdir -p "$outdir"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    ${pkgs.ffmpeg}/bin/ffmpeg -y -i "$input" -vf 'scale=512:288' -frames:v 1 "$tmp/frame.png" -loglevel error
    ${pkgs.matugen}/bin/matugen image "$tmp/frame.png" -m dark --json hex --source-color-index 0 </dev/null > "$tmp/palette.json"
    palette="$tmp/palette.json"

    # CSS (waybar + walker)
    ${pkgs.jq}/bin/jq -r '
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
    ' "$palette" > "$outdir/colors.css"
    # Translucent variant of the surface color ("frosted glass")
    rgb=$(${pkgs.jq}/bin/jq -r '.colors.surface.dark.color' "$palette" | tr -d '#')
    hard=$((0x$(printf '%s' "$rgb" | cut -c1-2)))
    soft=$((0x$(printf '%s' "$rgb" | cut -c3-4)))
    deep=$((0x$(printf '%s' "$rgb" | cut -c5-6)))
    printf '@define-color base_glass rgba(%s, %s, %s, 0.45);\n' "$hard" "$soft" "$deep" >> "$outdir/colors.css"
    grep -q '@define-color' "$outdir/colors.css"

    # Flat JSON, same roles as colors.css, for QML (Quickshell settings app).
    # panel: matugen's own "surface container high" role (Material 3 elevated
    # surface token) rather than surface+alpha — a nearly-opaque card still
    # reads as on-theme instead of a flat dark blend. #f2 prefix = ~0.95 alpha.
    ${pkgs.jq}/bin/jq -n --slurpfile p "$palette" --argjson gr "$hard" --argjson gg "$soft" --argjson gb "$deep" '
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
    ' > "$outdir/colors.json"
    grep -q '"accent"' "$outdir/colors.json"

    # Lua table loaded by theme.lua (nvim)
    ${pkgs.jq}/bin/jq -r '
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
    ' "$palette" > "$outdir/colors-matugen.lua"
    grep -q '^return {' "$outdir/colors-matugen.lua"

    # Rofi: .rasi syntax, no @define-color
    ${pkgs.jq}/bin/jq -r '
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
    ' "$palette" > "$outdir/rofi-colors.rasi"
    erb=$(${pkgs.jq}/bin/jq -r '.colors.error.dark.color' "$palette" | tr -d '#')
    er=$((0x$(printf '%s' "$erb" | cut -c1-2)))
    eg=$((0x$(printf '%s' "$erb" | cut -c3-4)))
    eb=$((0x$(printf '%s' "$erb" | cut -c5-6)))
    sed -i "s/^}/  error-soft: rgba($er, $eg, $eb, 0.18);\n}/" "$outdir/rofi-colors.rasi"
    grep -q 'error-soft' "$outdir/rofi-colors.rasi"

    # Kitty: background/foreground/cursor + 16 ANSI colors
    ${pkgs.jq}/bin/jq -r '
      "background            " + .colors.surface_variant.dark.color,
      "foreground            " + .colors.on_surface.dark.color,
      "cursor                " + .colors.primary.dark.color,
      "cursor_text_color     " + .colors.on_primary.dark.color,
      "selection_background  " + .colors.primary.dark.color,
      "selection_foreground  " + .colors.on_primary.dark.color
    ' "$palette" > "$outdir/kitty.conf"
    printf 'background_opacity 0.40\n' >> "$outdir/kitty.conf"
    # Luminance clamp: keeps colors readable on a translucent background.
    ${pkgs.jq}/bin/jq -r '
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
    ' "$palette" >> "$outdir/kitty.conf"
    grep -q '^color15 ' "$outdir/kitty.conf"

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
    sf=$(${pkgs.jq}/bin/jq -r '.colors.surface.dark.color' "$palette")
    sfv=$(${pkgs.jq}/bin/jq -r '.colors.surface_variant.dark.color' "$palette")
    onsf=$(${pkgs.jq}/bin/jq -r '.colors.on_surface.dark.color' "$palette")
    prim=$(${pkgs.jq}/bin/jq -r '.colors.primary.dark.color' "$palette")
    tert=$(${pkgs.jq}/bin/jq -r '.colors.tertiary.dark.color' "$palette")
    outl=$(${pkgs.jq}/bin/jq -r '.colors.outline.dark.color' "$palette")
    cat > "$outdir/zenChrome.css" <<EOF
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
    grep -q -- '--zen-colors-primary' "$outdir/zenChrome.css"

    # Vesktop (Vencord)
    cat > "$outdir/vesktop.theme.css" <<EOF
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
    grep -q -- '--background-primary' "$outdir/vesktop.theme.css"

    # Propagate to already-running apps that don't watch the palette dir
    # themselves (Quickshell/walker/rofi do, by reading fresh at each launch
    # or via FileView watchChanges — waybar needs an explicit kick).
    ${pkgs.procps}/bin/pkill waybar 2>/dev/null || true
    ${pkgs.waybar}/bin/waybar >/dev/null 2>&1 & disown || true
  '';
in
{
  options.styling.paletteDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.cache/theming/current";
    description = ''
      Runtime directory holding the current matugen palette (colors.css,
      colors.json, colors-matugen.lua, rofi-colors.rasi, kitty.conf,
      zenChrome.css, vesktop.theme.css), regenerated by `theme-apply` —
      no longer a Nix store package, so wallpaper switching (see
      modules/home/quickshell) doesn't need a rebuild to re-theme.
    '';
  };

  config.home.packages = [ themeApply ];
}
