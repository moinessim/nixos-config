{  lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" (if isDarwin then ''
    sh -c 'col -bx | bat -l man -p'
    '' else ''
    cat "$1" | col -bx | bat --language man --style plain
  ''));

  jira-cli = pkgs.symlinkJoin {
    name = "jira-cli";
    paths = [
      pkgs.jira-cli-go
    ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/jira --run 'export JIRA_API_TOKEN="$(pass TopManage/jira-cli)"'
      '';
  };

  shellAliases = {
    gv = "nvim -c ':G | :only' .";
    gf = "git fetch";
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gcp = "git cherry-pick";
    gdiff = "git diff";
    gd = "git diff";
    gl = "git prettylog";
    gp = "git push";
    gs = "git status";
    gt = "git tag";
  } // (if isLinux then {
    # Two decades of using a Mac has made this such a strong memory
    # that I'm just going to keep it consistent.
    pbcopy = "xclip";
    pbpaste = "xclip -o";
  } else {});

in {
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.asciinema
    pkgs.bat
    pkgs.fd
    pkgs.fzf
    pkgs.htop
    pkgs.btop
    pkgs.jq
    pkgs.ripgrep
    pkgs.tree
    pkgs.watch
    pkgs.vifm-full
    pkgs.qtpass
    pkgs.unzip
    pkgs.zip
    pkgs.mirrord

    jira-cli

    # Node is required for Copilot.vim
    pkgs.nodejs
  ] ++ (lib.optionals isDarwin [
    # This is automatically setup on Linux
    pkgs.cachix
    pkgs.tailscale
  ]) ++ (lib.optionals isLinux [
    pkgs.chromium
    pkgs.firefox
    pkgs.zathura
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "${pkgs.neovim}/bin/nvim --clean";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };

  home.file.".gdbinit".source = ./gdbinit;
  home.file.".inputrc".source = ./inputrc;

  xdg.configFile."i3/config".text = builtins.readFile ./i3;
  xdg.configFile."devtty/config".text = builtins.readFile ./devtty;

  # Rectangle.app. This has to be imported manually using the app.
  xdg.configFile."rectangle/RectangleConfig.json".text = builtins.readFile ./RectangleConfig.json;

  # tree-sitter parsers
  xdg.configFile."nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
  xdg.configFile."nvim/queries/proto/folds.scm".source =
    "${sources.tree-sitter-proto}/queries/folds.scm";
  xdg.configFile."nvim/queries/proto/highlights.scm".source =
    "${sources.tree-sitter-proto}/queries/highlights.scm";
  xdg.configFile."nvim/queries/proto/textobjects.scm".source =
    ./textobjects.scm;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/about" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/unknown" = "org.qutebrowser.qutebrowser.desktop";
    };
  };

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = !isDarwin;

  programs.password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [
          exts.pass-otp
          exts.pass-import
      ]);
      settings.PASSWORD_STORE_KEY = "23AAF91CB405F187";
  };

  programs.rofi = {
      enable = isLinux;
      theme = "gruvbox-dark";
      font = "Monaco for Powerline 12";
      extraConfig = {
          dpi = 94;
      };
  };

  programs.rofi.pass.enable = true;

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;
    inherit shellAliases;
  };

  programs.direnv= {
    enable = true;

    config = {
      whitelist = {
        prefix= [
        ];

        exact = ["$HOME/.envrc"];
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" [
      "source ${sources.theme-bobthefish}/functions/fish_prompt.fish"
      "source ${sources.theme-bobthefish}/functions/fish_right_prompt.fish"
      "source ${sources.theme-bobthefish}/functions/fish_title.fish"
      (builtins.readFile ./config.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
    ]);

    inherit shellAliases;

    plugins = map (n: {
      name = n;
      src  = sources.${n};
    }) [
      "fish-fzf"
      "fish-foreign-env"
      "theme-bobthefish"
    ];
  };

  programs.git = {
    enable = true;
    userName = "Moises Nessim";
    userEmail = "moises.nessim@topmanage.com";
    aliases = {
      cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop\\|main' | xargs -n 1 -r git branch -d";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
    };
    hooks = {
        prepare-commit-msg = ./prepare-commit-msg;
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "moinessim";
      push.default = "tracking";
      init.defaultBranch = "master";
    };
  };

  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    shortcut = "l";
    secureSocket = false;

    extraConfig = ''
      set -ga terminal-overrides ",*256col*:Tc"

      set -g @dracula-show-battery false
      set -g @dracula-show-network false
      set -g @dracula-show-weather false

      bind -n C-k send-keys "clear"\; send-keys "Enter"

      run-shell ${sources.tmux-pain-control}/pain_control.tmux
      run-shell ${sources.tmux-dracula}/dracula.tmux
    '';
  };

  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";

      key_bindings = [
        { key = "K"; mods = "Command"; chars = "ClearHistory"; }
        { key = "V"; mods = "Command"; action = "Paste"; }
        { key = "C"; mods = "Command"; action = "Copy"; }
        { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
        { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
      ];
    };
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  programs.i3status = {
    enable = isLinux;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  # programs.pywal.enable = true;

  programs.neovim = {
    enable = true;

    withPython3 = true;
    extraPython3Packages = (p: with p; [
      # For nvim-magma
      jupyter-client
      cairosvg
      plotly
      #pnglatex
      #kaleido
    ]);

    plugins = with pkgs; [
      customVim.which-key-nvim
      customVim.vim-copilot
      customVim.vim-cue
      customVim.vim-fish
      customVim.vim-fugitive
      customVim.vim-glsl
      customVim.vim-misc
      customVim.vim-pgsql
      customVim.vim-tla
      customVim.pigeon
      customVim.AfterColors

      customVim.vim-devicons
      customVim.vim-nord
      customVim.nvim-lspconfig
      customVim.nvim-plenary # required for telescope
      customVim.nvim-telescope
      customVim.nvim-treesitter
      customVim.nvim-treesitter-playground
      customVim.nvim-treesitter-textobjects
      customVim.nvim-magma
      customVim.vifm-vim
      customVim.toggleterm
      customVim.comment-nvim
      vimPlugins.nvim-surround

      vimPlugins.vim-airline
      vimPlugins.vim-airline-themes
      vimPlugins.vim-eunuch
      vimPlugins.vim-gitgutter

      vimPlugins.cmp-nvim-lsp
      vimPlugins.cmp-buffer
      vimPlugins.cmp-path
      vimPlugins.cmp-cmdline
      vimPlugins.nvim-cmp
      vimPlugins.lspkind-nvim

      vimPlugins.nvim-dap
      vimPlugins.nvim-dap-ui
      vimPlugins.nvim-dap-virtual-text

      vimPlugins.trouble-nvim
      vimPlugins.nvim-web-devicons # required for trouble-nvim

      vimPlugins.vim-markdown
      vimPlugins.markdown-preview-nvim
      vimPlugins.vim-nix
      vimPlugins.typescript-vim
      vimPlugins.plantuml-syntax
    ];

    extraConfig = (import ./vim-config.nix) { inherit sources pkgs; };
  };

  programs.qutebrowser = {
      enable = true;
      extraConfig =
        let args = ''-U secret -u "(?:user|login|username): (.+)"''; in ''
        config.set("colors.webpage.darkmode.enabled", True)
        config.set("zoom.default", "100%")
        config.set("editor.command", ["kitty", "nvim", "{file}", "-c", "normal {line}G{column0}l"])

        config.bind('<z><l>', 'spawn --userscript qute-pass ${args}')
        config.bind('<z><u><l>', 'spawn --userscript qute-pass ${args} --username-only')
        config.bind('<z><p><l>', 'spawn --userscript qute-pass ${args} --password-only')
        config.bind('<z><o><l>', 'spawn --userscript qute-pass ${args} --otp-only')
      '';
  };

  services.gpg-agent = {
    enable = isLinux;
    pinentryFlavor = "tty";

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  services.picom.enable = isLinux;

  services.safeeyes.enable = isLinux;

  services.copyq = {
    enable = isLinux;
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = lib.mkIf isLinux {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };
}
