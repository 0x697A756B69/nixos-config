-- Palette Material You du wallpaper (voir modules/home/theming/matugen).
-- Chemin absolu vers ~/.config/nvim/... d'izuki : le fichier est une
-- symlink vers le store (monde lisible), donc ce chemin fonctionne À LA
-- FOIS pour izuki et pour root (sudo) -> la même palette partout.
local pf = "/home/izuki/.config/nvim/lua/colors-matugen.lua"
local ok, c = pcall(dofile, pf)
if not ok or type(c) ~= "table" then
  c = { foreground = "#cdd6f4", comment = "#8a8fa3", accent = "#cba6f7",
        on_accent = "#111111", surface = "#313244", background = "#181825",
        error = "#f38ba8", border = "#585b70", secondary = "#f5c2e7",
        tertiary = "#94e2d5" }
end

-- Transparence (comme kitty) : fond nvim = NONE pour laisser voir la
-- transparence de kitty (background_opacity 0.40) et le flou Hyprland.
vim.opt.pumblend = 25
vim.opt.winblend = 15

-- hl(name, fg, bg, style) : applique une couleur matugen à un groupe.
local function hl(name, fg, bg, style)
  vim.api.nvim_set_hl(0, name, {
    fg = fg or "NONE",
    bg = bg or "NONE",
    italic = style and style:find("italic") ~= nil,
    bold = style and style:find("bold") ~= nil,
    underline = style and style:find("underline") ~= nil,
  })
end

-- --- Base (fond, texte, commentaires, sélection) ---
hl("Normal", c.foreground, "NONE")
hl("NormalNC", c.foreground, "NONE")
hl("NormalFloat", c.foreground, "NONE")
hl("Comment", c.comment)
hl("LineNr", c.comment)
hl("CursorLine", nil, c.surface)
hl("CursorLineNr", c.accent)
hl("Visual", c.on_accent, c.accent)
hl("Search", c.on_accent, c.accent)
hl("CurSearch", c.on_accent, c.accent)
hl("IncSearch", c.on_accent, c.accent)
hl("Cursor", c.on_accent, c.accent)
hl("iCursor", c.on_accent, c.accent)
hl("WinSeparator", c.border)
hl("VertSplit", c.border)
hl("FloatBorder", c.border)
hl("DiagnosticError", c.error)
hl("Error", c.error)
hl("SpellBad", c.error, nil, "underline")
hl("WinBar", c.foreground, c.surface)
hl("WinBarNC", c.comment, c.surface)
hl("StatusLine", c.on_accent, c.accent)
hl("StatusLineNC", c.foreground, c.surface)

-- --- Syntaxe (groupes de base Vim) ---
-- Neovim >= 0.9 lie par défaut les captures treesitter (@keyword, @string,
-- @function, @type, ...) sur ces groupes historiques : les colorer suffit
-- donc à couvrir le highlighting treesitter sans toucher au moteur lui-même
-- ni redéfinir chaque capture @xxx individuellement.
hl("Keyword", c.accent)
hl("Conditional", c.accent)
hl("Repeat", c.accent)
hl("Label", c.accent)
hl("Statement", c.accent)
hl("Exception", c.accent)
hl("String", c.secondary)
hl("Character", c.secondary)
hl("Number", c.secondary)
hl("Boolean", c.secondary)
hl("Float", c.secondary)
hl("Constant", c.secondary)
hl("Function", c.accent)
hl("Identifier", c.foreground)
hl("Type", c.tertiary)
hl("Structure", c.tertiary)
hl("Typedef", c.tertiary)
hl("StorageClass", c.tertiary)
hl("Operator", c.border)
hl("Special", c.border)
hl("Delimiter", c.border)
hl("PreProc", c.tertiary)
hl("Include", c.accent)
hl("Define", c.tertiary)
hl("Macro", c.tertiary)
hl("Tag", c.accent)

-- --- Neotree (explorateur) ---
hl("NeoTreeNormal", c.foreground, "NONE")
hl("NeoTreeNormalNC", c.foreground, "NONE")
hl("NeoTreeCursorLine", c.foreground, c.surface)
hl("NeoTreeFileName", c.foreground)
hl("NeoTreeFileNameOpened", c.foreground)
hl("NeoTreeDirectoryName", c.accent)
hl("NeoTreeRootName", c.accent, nil, "bold")
hl("NeoTreeTitleBar", c.foreground, c.surface)
hl("NeoTreeFloatBorder", c.border)
hl("NeoTreeFloatTitle", c.foreground, c.surface)
hl("NeoTreeIndentMarker", c.border)
hl("NeoTreeExpandMarker", c.comment)
hl("NeoTreeFolderArrowCollapsed", c.comment)
hl("NeoTreeFolderArrowOpen", c.comment)
hl("NeoTreeTabActive", c.on_accent, c.accent, "bold")
hl("NeoTreeTabInactive", c.foreground, c.surface)
hl("NeoTreeBufferLabel", c.foreground)
hl("NeoTreeGitAdded", c.accent)
hl("NeoTreeGitDeleted", c.error)
hl("NeoTreeGitModified", c.accent)
hl("NeoTreeGitConflict", c.error)
hl("NeoTreeGitRenamed", c.accent)
hl("NeoTreeGitUntracked", c.comment)
hl("NeoTreeGitStaged", c.accent)
hl("NeoTreeGitUnstaged", c.comment)
hl("NeoTreeDirectoryIcon", c.accent)
hl("SignColumn", "NONE", "NONE")
hl("NeoTreeSignColumn", "NONE", "NONE")

-- --- Interface générale : tout aligner sur matugen ---
local ui = {
  -- Diagnostics info/hint
  "DiagnosticInfo", "DiagnosticHint", "DiagnosticFloatingInfo",
  "DiagnosticFloatingHint", "DiagnosticVirtualTextInfo",
  "DiagnosticVirtualTextHint", "DiagnosticSignInfo", "DiagnosticSignHint",
  "DiagnosticUnderlineInfo", "DiagnosticUnderlineHint",
  "LspDiagnosticsDefaultInformation", "LspDiagnosticsDefaultHint",
  "LspDiagnosticsInformation", "LspDiagnosticsHint",
  "LspDiagnosticsVirtualTextInformation", "LspDiagnosticsVirtualTextHint",
  -- Completion (Cmp + Blink) : icônes de kind
  "CmpItemKindFunction", "CmpItemKindMethod", "CmpItemKindModule",
  "CmpItemKindStruct", "CmpItemKindConstructor", "CmpItemKindEvent",
  "CmpItemKindOperator", "CmpItemKindProperty", "CmpItemKindFile",
  "CmpItemKindFolder", "CmpItemKindTypeParameter", "CmpItemKindCopilot",
  "CmpItemKindText", "CmpItemKindEnumMember",
  "BlinkCmpKindFunction", "BlinkCmpKindMethod", "BlinkCmpKindModule",
  "BlinkCmpKindStruct", "BlinkCmpKindConstructor", "BlinkCmpKindEvent",
  "BlinkCmpKindOperator", "BlinkCmpKindProperty", "BlinkCmpKindFile",
  "BlinkCmpKindFolder", "BlinkCmpKindTypeParameter", "BlinkCmpKindCopilot",
  "BlinkCmpKindText", "BlinkCmpKindEnumMember",
  -- FzfLua (picker)
  "FzfLuaFzfPrompt", "FzfLuaFzfMatch", "FzfLuaPathColNr", "FzfLuaTabTitle",
  "FzfLuaBufFlagAlt", "FzfLuaNormal", "FzfLuaBorder", "FzfLuaTitle",
  "FzfLuaCursorLine", "FzfLuaCursorLineNr", "FzfLuaSearch",
  -- BufferLine (onglets buffers)
  "BufferLineInfoSelected", "BufferLineHintSelected",
  -- Neogit
  "NeogitDiffHeader", "NeogitFilePath", "NeogitHunkHeaderHighlight",
  "NeogitChangeModified", "NeogitNotificationInfo", "NeogitPopupActionKey",
  "NeogitPopupConfigKey", "NeogitPopupOptionKey", "NeogitPopupSwitchKey",
  "NeogitUnpushedTo", "NeogitTagDistance", "NeogitGraphBlue",
  "NeogitGraphCyan", "NeogitGraphPurple", "NeogitGraphBoldBlue",
  "NeogitGraphBoldCyan", "NeogitGraphBoldPurple",
  -- Dashboard / Alpha / Mini
  "DashboardDesc", "DashboardMruTitle", "DashboardProjectTitle",
  "DashboardFiles", "DashboardHeader", "AlphaHeader", "AlphaButtons",
  "MiniStarterHeader", "MiniStarterItemBullet", "MiniStatuslineInactive",
  "MiniIconsBlue", "MiniIconsCyan",
  -- Divers UI
  "Directory", "MoreMsg", "Question", "Title", "ManBold", "qfFileName",
  "healthSuccess", "TelescopeMatching", "FlashMatch", "DapLogPoint",
}
for _, g in ipairs(ui) do hl(g, c.accent) end

-- FzfLua : fond/bordures explicites pour l'effet "page".
hl("FzfLuaNormal", c.foreground, c.surface)
hl("FzfLuaBorder", c.border, c.surface)
hl("FzfLuaTitle", c.foreground, c.accent, "bold")
hl("FzfLuaCursorLine", c.foreground, c.surface)
hl("FzfLuaCursorLineNr", c.accent, c.surface)
hl("FzfLuaSearch", c.on_accent, c.accent)

-- --- Lualine (barre du bas : modes + position ligne:col) ---
local lue = pcall(require, "lualine")
if lue then
  local lc = {
    normal  = { a = { fg = c.on_accent, bg = c.accent, gui = "bold" },
                b = { fg = c.foreground, bg = c.surface },
                c = { fg = c.foreground, bg = "NONE" } },
    insert  = { a = { fg = c.background, bg = c.accent, gui = "bold" },
                b = { fg = c.foreground, bg = c.surface },
                c = { fg = c.foreground, bg = "NONE" } },
    visual  = { a = { fg = c.on_accent, bg = c.accent, gui = "bold" },
                b = { fg = c.foreground, bg = c.surface },
                c = { fg = c.foreground, bg = "NONE" } },
    replace = { a = { fg = c.on_accent, bg = c.error, gui = "bold" },
                b = { fg = c.foreground, bg = c.surface },
                c = { fg = c.foreground, bg = "NONE" } },
    command = { a = { fg = c.on_accent, bg = c.accent, gui = "bold" },
                b = { fg = c.foreground, bg = c.surface },
                c = { fg = c.foreground, bg = "NONE" } },
    inactive = { a = { fg = c.comment, bg = c.surface },
                 b = { fg = c.comment, bg = c.surface },
                 c = { fg = c.comment, bg = "NONE" } },
  }
  require("lualine").setup({ options = { theme = lc } })
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then vim.cmd("Neotree filesystem left") end
  end,
})
