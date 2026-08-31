{ config, pkgs, ... }:

{
  # Palette Material You générée par matugen (voir modules/home/theming/matugen) :
  # jamais branchée avant cette étape, theme.lua faisait systématiquement un
  # fallback silencieux sur des couleurs codées en dur. `dofile` lit ce chemin
  # absolu (voir theme.lua) donc le fichier doit être déployé exactement là.
  xdg.configFile."nvim/lua/colors-matugen.lua".source =
    "${config.styling.palette}/colors-matugen.lua";
  xdg.configFile."nvim/lua/theme.lua".source = ./theme.lua;

  #Install Nixvim
  programs.nixvim = {
    enable = true;

    # ---------- Apparence ----------
    # Pas de colorscheme dédié : nvim gère les syntaxes via treesitter (API
    # native) et le thème par défaut. La palette Material You du wallpaper
    # (voir modules/home/theming/matugen) est appliquée par-dessus via
    # theme.lua pour le fond, le texte, les commentaires, la sélection, les
    # accents et les groupes de syntaxe de base.
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

    # Chemin absolu (voir theme.lua) : fonctionne pour izuki comme pour un
    # éventuel `sudo nvim` (symlink store, monde lisible).
    extraConfigLua = ''
      dofile("/home/izuki/.config/nvim/lua/theme.lua")
    '';
  };
}
