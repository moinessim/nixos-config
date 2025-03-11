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

  jira-select-project = pkgs.writeShellScriptBin "jira-select-project"
      ''
        set -euo pipefail
        ${jira-cli}/bin/jira project list | ${pkgs.fzf}/bin/fzf | ${pkgs.gawk}/bin/awk '{print $1}'
      '';

  jira-select-issue = pkgs.writeShellScriptBin "jira-select-issue"
      ''
        set -euo pipefail
        project=$(${jira-select-project}/bin/jira-select-project)
        ${jira-cli}/bin/jira issue list --plain --columns key,type,status,summary  --project "$project" | ${pkgs.fzf}/bin/fzf | ${pkgs.gawk}/bin/awk '{print $1}'
      '';

  jira-view-issue = pkgs.writeShellScriptBin "jira-view-issue"
      ''
        set -euo pipefail
        issue=$(${jira-select-issue}/bin/jira-select-issue)
        ${jira-cli}/bin/jira issue view "$issue"
      '';

  jira-issue-create = pkgs.writeShellScriptBin "jira-issue-create"
      ''
        set -euo pipefail
        project=$(${jira-select-project}/bin/jira-select-project)
        ${jira-cli}/bin/jira issue create --project "$project"
      '';

  dpi-toggle = pkgs.writeShellScriptBin "dpi-toggle" ''

      # Get current DPI setting
      current_dpi=$(xrdb -query | grep -E 'Xft.dpi' | awk '{print $2}')

      # Define DPI values
      LOW_DPI=96
      HIGH_DPI=144

      # Toggle DPI
      if [[ "$current_dpi" == "$LOW_DPI" ]]; then
          # Set high DPI
          xrandr --dpi $HIGH_DPI
          xrdb -merge <<< "Xft.dpi: $HIGH_DPI"
      else
          # Set low DPI
          xrandr --dpi $LOW_DPI
          xrdb -merge <<< "Xft.dpi: $LOW_DPI"
      fi


      # Update GTK settings
      if [[ "$current_dpi" == "$LOW_DPI" ]]; then
          echo -e "[Settings]\ngtk-xft-dpi=$((HIGH_DPI * 1000))" > ~/.config/gtk-3.0/settings.ini
      else
          echo -e "[Settings]\ngtk-xft-dpi=$((LOW_DPI * 1000))" > ~/.config/gtk-3.0/settings.ini
      fi


      # Update Qt scaling
      if [[ "$current_dpi" == "$LOW_DPI" ]]; then
          export QT_SCALE_FACTOR=1.5
          export QT_ENABLE_HIGHDPI_SCALING=1
      else
          export QT_SCALE_FACTOR=1
          export QT_ENABLE_HIGHDPI_SCALING=
      fi

      # Update i3status
      if [[ "$current_dpi" == "$LOW_DPI" ]]; then
        echo hdpi  > ~/.config/i3status/dpi
      else
        echo "" > ~/.config/i3status/dpi
      fi

      # Reload i3 configuration
      i3-msg reload

      qutebrowser --no-window :restart

      '';

  shellAliases = {
    gv = "nvim -c ':G | :only' .";
    gf = "git fetch";
    ga = "git add";
    gba = "git branch -r --no-merged $(git branch -l main master --format '%(refname:short)' | head -n 1)";
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
    pkgs.yq
    pkgs.ripgrep
    pkgs.tree
    pkgs.watch
    pkgs.vifm-full
    pkgs.qtpass
    pkgs.gawk
    pkgs.unzip
    pkgs.zip
    pkgs.mirrord

    jira-cli
    jira-select-project
    jira-select-issue
    jira-view-issue
    jira-issue-create
    dpi-toggle

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
      font = "Monaco for Powerline 14";
      extraConfig = {
          dpi = 0;
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
      "ethernet _first_".enable = false;
      "battery all".enable = false;
      "read_file DPI" = {
        position = 0;
        settings = {
          path = "/home/moisesnessim/.config/i3status/dpi";
        };
      };
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

        config.bind('ca', 'set -t content.javascript.clipboard access ;; cmd-later 10s set -p content.javascript.clipboard none')
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
