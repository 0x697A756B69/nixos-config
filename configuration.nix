# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

 # Bootloader 
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.udev.extraRules = ''
  # Dongle USB custom (VID:PID 3554:f508) — accès utilisateur
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="3554", ATTRS{idProduct}=="f508", MODE="0666", GROUP="users"

  # Même device — désactive l'autosuspend de façon persistante
  SUBSYSTEM=="usb", ATTR{idVendor}=="3554", ATTR{idProduct}=="f508", TEST=="power/control", ATTR{power/control}="on"
'';
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages;

  boot.kernelParams = [
  "usbcore.quirks=3554:f508:k"
];
 
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable bluethooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_FR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Flakes settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the Hyprland Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "hyprland";
  services.desktopManager.plasma6.enable = false;
  # Configure Nvidia Driver
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  hardware.nvidia.modesetting.enable = true;
  hardware.graphics.enable32Bit = true;

  # Configure Hyprland + Nvidia
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."izuki" = {
    isNormalUser = true;
    description = "izuki";
    extraGroups = [ "networkmanager" "wheel" "input" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  services.displayManager.autoLogin = {
   enable = true;
   user = "izuki";
  };

  # Install Hyprland.
  programs.hyprland.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Install steam.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  programs.gamemode.enable = true;

  programs.steam.extraCompatPackages = [ pkgs.steamtinkerlaunch ];



  # Install Spicetify.
  programs.spicetify =
    let spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
    in {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
      enabledCustomApps = with spicePkgs.apps; [
        marketplace
      ];
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
    };

  #Install Nixvim
  programs.nixvim = {
    enable = true;

    # ---------- Apparence ----------
    colorschemes.catppuccin.enable = true;
    colorschemes.catppuccin.settings.flavour = "mocha";
    colorschemes.catppuccin.settings.term_colors = true;

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
    plugins.cord.enaable = true;

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
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 0 then
            vim.cmd("Neotree filesystem left")
          end
        end,
      })
    '';
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    glib
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget

  vscodium
  nixd
  discord
  opencode-desktop
  protonup-qt
  (symlinkJoin {
    name = "modrinth-app";
    paths = [ modrinth-app ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ModrinthApp \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
  })
  temurin-jre-bin-21  # Minecraft
  temurin-jre-bin-25  # Minecraft 
  git
  curl 
  unzip
  cabextract
  p7zip
  file
  steamtinkerlaunch
  ];

  #List packages installed in steam profil
  programs.steam.package = pkgs.steam.override {
    extraPkgs = pkgs': with pkgs'; [
      libXcursor
      libXi
      libXinerama
      libXScrnSaver
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib # Provides libstdc++.so.6
      libkrb5
      keyutils
      # Add other libraries as needed
    ];
};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
