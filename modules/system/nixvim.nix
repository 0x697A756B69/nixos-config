{ config, pkgs, ... }:

{
  #Install Nixvim
  programs.nixvim = {
    enable = true;

    # ---------- Apparence ----------
    # Pas de colorscheme dédié : nvim gère les syntaxes via treesitter (API
    # native) et le thème par défaut. La palette Material You du wallpaper
    # (voir modules/theming.nix) est appliquée par-dessus via extraConfigLua
    # pour le fond, le texte, les commentaires, la sélection et les accents.
    plugins.web-devicons.enable = true;
    plugins.bufferline.enable = true;
    plugins.lualine.enable = true;

    # ---------- Arbre syntaxique (treesitter, API native) ----------
    plugins.treesitter.enable = true;
    plugins.treesitter.highlight.enable = true;
    plugins.treesitter.indent.enable = true;

    # ---------- Exploration de fichiers (neo-tree) ----------
    plugins.neo-tree.enable = true;
    plugins.neo-tree.settings.window.position = "left";
    plugins.neo-tree.settings.filesystem.follow_current_file.enabled = true;
    plugins.neo-tree.settings.source_selector.winbar = true;
    plugins.neo-tree.settings.source_selector.statusline = false;

    # ---------- Recherche floue (fzf-lua) ----------
    plugins.fzf-lua.enable = true;

    # ---------- Autocomplétion (nvim-cmp -> plugins.cmp) ---------
    plugins.cmp.enable = true;
    plugins.cmp.settings.sources = [
      { name = "nvim_lsp"; }
      { name = "path"; }
      { name = "buffer"; }
    ];
    plugins.cmp.settings.snippet.expand = ''
      function(args)
        require('luasnip').lsp_expand(args.body)
      end
    '';
    plugins.cmp.settings.mapping = {
      "<C-d>" = "cmp.mapping.scroll_docs(-4)";
      "<C-f>" = "cmp.mapping.scroll_docs(4)";
      "<C-Space>" = "cmp.mapping.complete()";
      "<C-e>" = "cmp.mapping.abort()";
      "<CR>" = "cmp.mapping.confirm({ select = true })";
      "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' })";
      "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 's' })";
    };
    plugins.cmp-nvim-lsp.enable = true;
    plugins.cmp-path.enable = true;
    plugins.cmp-buffer.enable = true;
    plugins.luasnip.enable = true;
    plugins.cmp_luasnip.enable = true;
    plugins.lspkind.enable = true;

    # ---------- Formatage à la sauvegarde (conform-nvim) ----------
    plugins.conform-nvim.enable = true;
    plugins.conform-nvim.settings.formatters_by_ft.nix = [ "nixpkgs-fmt" ];

    # ---------- LSP (nixd pour Nix) ----------
    plugins.lsp.enable = true;
    plugins.lsp.servers.nixd.enable = true;
    plugins.lsp.servers.nixd.package = pkgs.nixd;
    plugins.lsp.keymaps.lspBuf = {
      "gd" = "definition";
      "K" = "hover";
      "gi" = "implementation";
      "gr" = "references";
    };
    plugins.lsp.keymaps.diagnostic = {
      "[d" = "goto_prev";
      "]d" = "goto_next";
    };
    # ---------- Git ----------
    plugins.gitsigns.enable = true;
    plugins.fugitive.enable = true;

    # ---------- Productivity ----------
    plugins.which-key.enable = true;
    plugins.nvim-autopairs.enable = true;
    plugins.comment.enable = true;
    plugins.cord.enable = true;

    # ---------- Raccourcis ----------
    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle filesystem left<cr>";
        options.desc = "Explorateur de fichiers";
      }
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>FzfLua files<cr>";
        options.desc = "Rechercher un fichier";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>FzfLua git_files<cr>";
        options.desc = "Rechercher un fichier git";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>FzfLua buffers<cr>";
        options.desc = "Basculer de buffer";
      }
      {
        mode = "n";
        key = "<leader>g";
        action = "<cmd>Git<cr>";
        options.desc = "Ouvrir fugitive";
      }
      {
        mode = "n";
        key = "<leader>fw";
        action = "<cmd>FzfLua live_grep<cr>";
        options.desc = "Chercher une phrase dans le projet";
      }
    ];

    extraPlugins = with pkgs.vimPlugins; [ ];
    extraConfigLua = ''
      -- Palette Material You du wallpaper (voir modules/theming.nix).
      -- Chemin absolu vers ~/.config/nvim/... d'izuki : le fichier est une
      -- symlink vers le store (monde lisible), donc ce chemin fonctionne À LA
      -- FOIS pour izuki et pour root (sudo) -> la même palette partout.
      local pf = "/home/izuki/.config/nvim/lua/colors-matugen.lua"
      local ok, c = pcall(dofile, pf)
      if not ok or type(c) ~= "table" then
        c = { foreground = "#cdd6f4", comment = "#8a8fa3", accent = "#cba6f7",
              on_accent = "#111111", surface = "#313244", background = "#181825",
              error = "#f38ba8", border = "#585b70" }
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
    '';
  };
}
