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

  git-active-branches = pkgs.writeShellScriptBin "git-active-branches" ''
    # Determine the default branch dynamically (main or master)
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

    # List remote branches ahead of the base branch
    git branch -r | grep -v "origin/$BASE_BRANCH" | while read branch; do
        # Check if the remote branch has commits ahead of the base branch
        if [ -n "$(git log origin/"$BASE_BRANCH".."$branch" --oneline)" ]; then
            echo "$branch"
        fi
    done
    '';

  jira-cli = pkgs.symlinkJoin {
    name = "jira-cli";
    paths = [
      pkgs.unstable.jira-cli-go
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

  jira-select-projects = pkgs.writeShellScriptBin "jira-select-projects"
      ''
        set -euo pipefail
        ${jira-cli}/bin/jira project list | ${pkgs.fzf}/bin/fzf --multi | ${pkgs.gawk}/bin/awk '{print $1}'
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
        ${jira-cli}/bin/jira issue view "$issue" "$@"
      '';

  jira-issue-create = pkgs.writeShellScriptBin "jira-issue-create"
      ''
        set -euo pipefail
        project=$(${jira-select-project}/bin/jira-select-project)
        ${jira-cli}/bin/jira issue create --project "$project"
      '';

  jira-issue-create-in-projects = pkgs.writeShellScriptBin "jira-issue-create-in-projects"
      ''
        set -euo pipefail
        issueType=$(
        ${pkgs.fzf}/bin/fzf <<< $'Bug\nFeature Request\nNew Feature\nImprovement\nSub-task\nStory\nTask\nTechnical task\nEscalation')
        read -p "Summary: " summary
        read -p "Set body? [y/N] " set_body
        if [[ "$set_body" == "y" ]]; then
          TEMP_FILE=$(mktemp)
          nvim "$TEMP_FILE"
          body=$(cat "$TEMP_FILE")
          rm "$TEMP_FILE"
        else
          body=""
        fi
        read -p "Label: " label
        if [[ -n "$label" ]]; then
          label="--label $label"
        else
          label=""
        fi
        projects=$(${jira-select-projects}/bin/jira-select-projects)
        for project in $projects; do
          ${jira-cli}/bin/jira issue create --no-input --type "$issueType" --summary "$summary" --project "$project" --body="$body" $label
        done
      '';

  jira-branch-from-issue = pkgs.writeShellScriptBin "jira-branch-from-issue" ''

    usage(){
      echo "Usage: $0 [-d|--dry-run] [-h|--help] <ISSUE_KEY>"
    }

    while [ $# -gt 0 ]; do
      case "$1" in
        -h|--help)
          usage
          exit 0
          ;;
        -d|--dry-run)
          DRY_RUN=true
          ;;
        *)
          ISSUE="$1"
          ;;
      esac
      shift
    done


    if [ -z "$ISSUE" ];
    then
      DATA=$(${jira-view-issue}/bin/jira-view-issue --raw)
    else
      DATA=$(${jira-cli}/bin/jira issue view "$ISSUE" --raw)
    fi


    if [ $? -ne 0 ]; then
      echo "Error fetching issue $ISSUE"
      exit 1
    fi

    KEY=$(echo "$DATA" | jq -r '.key')
    SUMMARY=$(echo "$DATA" | jq -r '.fields.summary')
    TYPE=$(echo "$DATA" | jq -r '.fields.issuetype.name' | tr '[:upper:]' '[:lower:]')

    # Determine prefix based on issue type
    case "$TYPE" in
      bug|bugfix|defect)
        PREFIX="bugfix"
        ;;
      hotfix)
        PREFIX="hotfix"
        ;;
      *)
        PREFIX="feature"
        ;;
    esac

    # Sanitize summary → slug
    SLUG=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g' | sed 's/^-//; s/-$//')

    BRANCH="''${PREFIX}/''${KEY}-''${SLUG}"

    if [ "$DRY_RUN" = true ]; then
      echo "Dry run: would create branch '$BRANCH'" 1>&2
      echo "$BRANCH"
      exit 0
    fi

    echo "Creating branch: $BRANCH" 1>&2
    git checkout -b "$BRANCH" 1>&2
    echo "$BRANCH"
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

  low-memory-notify = pkgs.writeShellScriptBin "low-memory-notify" ''
    set -eu

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus"

    mem_total_kb=$(${pkgs.gawk}/bin/awk '/MemTotal:/ { print $2; exit }' /proc/meminfo)
    mem_available_kb=$(${pkgs.gawk}/bin/awk '/MemAvailable:/ { print $2; exit }' /proc/meminfo)

    min_threshold_kb=$((1024 * 1024))
    threshold_kb=$((mem_total_kb / 10))
    if [ "$threshold_kb" -lt "$min_threshold_kb" ]; then
      threshold_kb=$min_threshold_kb
    fi

    state_dir="$runtime_dir/low-memory-notify"
    state_file="$state_dir/notified"
    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    if [ "$mem_available_kb" -gt "$threshold_kb" ]; then
      ${pkgs.coreutils}/bin/rm -f "$state_file"
      exit 0
    fi

    if [ -f "$state_file" ]; then
      exit 0
    fi

    top_process=$(${pkgs.procps}/bin/ps -eo pid=,comm=,rss= --sort=-rss | ${pkgs.gawk}/bin/awk 'NR == 1 { print $1 "\t" $2 "\t" $3; exit }')

    pid=$(printf '%s\n' "$top_process" | ${pkgs.gawk}/bin/awk -F '\t' '{ print $1 }')
    process_name=$(printf '%s\n' "$top_process" | ${pkgs.gawk}/bin/awk -F '\t' '{ print $2 }')
    rss_kb=$(printf '%s\n' "$top_process" | ${pkgs.gawk}/bin/awk -F '\t' '{ print $3 }')

    if [ -z "$process_name" ]; then
      process_name="unknown"
    fi

    if [ -z "$rss_kb" ]; then
      rss_kb=0
    fi

    mem_available_mib=$((mem_available_kb / 1024))
    threshold_mib=$((threshold_kb / 1024))
    rss_mib=$((rss_kb / 1024))

    ${pkgs.libnotify}/bin/notify-send \
      --app-name="System Monitor" \
      --urgency=critical \
      --hint=string:x-dunst-stack-tag:low-memory \
      "Low available memory" \
      "Available: ''${mem_available_mib} MiB (threshold: ''${threshold_mib} MiB)\nTop memory user: ''${process_name} (PID ''${pid:-?}, ''${rss_mib} MiB RSS)"

    : > "$state_file"
  '';

  ai-preserved-shell = pkgs.writeShellScriptBin "ai-preserved-shell" ''
    set -euo pipefail
    exec ${pkgs.coreutils}/bin/env PATH="$PATH" ${pkgs.bashInteractive}/bin/bash --noprofile --norc "$@"
  '';

  ai-shell = pkgs.writeShellScriptBin "ai-shell" ''
    set -euo pipefail

    source_config_dir=/home/moisesnessim/code/opencode-config
    ai_config_dir=/home/ai/.local/share/opencode-config

    if [ -L /home/ai/.config/opencode ]; then
      target=$(${pkgs.coreutils}/bin/readlink -f /home/ai/.config/opencode || true)
      if [ "$target" = "/home/moisesnessim/code/opencode-config" ]; then
        /run/wrappers/bin/sudo -u ai ${pkgs.coreutils}/bin/rm /home/ai/.config/opencode
        /run/wrappers/bin/sudo -u ai ${pkgs.coreutils}/bin/mkdir -p /home/ai/.config/opencode
      fi
    fi

    /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/mkdir -p /home/ai/.local/share
    /run/wrappers/bin/sudo ${pkgs.rsync}/bin/rsync -a --delete --exclude .git --exclude .worktrees --exclude node_modules "$source_config_dir/" "$ai_config_dir/"
    /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chown -R ai:ai "$ai_config_dir"

    exec /run/wrappers/bin/sudo \
      --preserve-env=COLORTERM,DBUS_SESSION_BUS_ADDRESS,DESKTOP_SESSION,DISPLAY,LANG,LC_ALL,LC_CTYPE,PATH,SSH_AUTH_SOCK,TERM,WAYLAND_DISPLAY,XAUTHORITY,XDG_CURRENT_DESKTOP,XDG_RUNTIME_DIR \
      -H -u ai \
      ${pkgs.coreutils}/bin/env \
      PATH="$PATH" \
      HOME=/home/ai \
      USER=ai \
      LOGNAME=ai \
      SHELL=${ai-preserved-shell}/bin/ai-preserved-shell \
      XDG_CONFIG_HOME=/home/ai/.config \
      XDG_CACHE_HOME=/home/ai/.cache \
      XDG_DATA_HOME=/home/ai/.local/share \
      BROWSER=${pkgs.xdg-utils}/bin/xdg-open \
      OPENCODE_CONFIG_DIR=/home/ai/.local/share/opencode-config \
      ${ai-preserved-shell}/bin/ai-preserved-shell
  '';

  ai-opencode = pkgs.writeShellScriptBin "ai-opencode" ''
    set -euo pipefail

    source_config_dir=/home/moisesnessim/code/opencode-config
    ai_config_dir=/home/ai/.local/share/opencode-config

    if [ -L /home/ai/.config/opencode ]; then
      target=$(${pkgs.coreutils}/bin/readlink -f /home/ai/.config/opencode || true)
      if [ "$target" = "/home/moisesnessim/code/opencode-config" ]; then
        /run/wrappers/bin/sudo -u ai ${pkgs.coreutils}/bin/rm /home/ai/.config/opencode
        /run/wrappers/bin/sudo -u ai ${pkgs.coreutils}/bin/mkdir -p /home/ai/.config/opencode
      fi
    fi

    /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/mkdir -p /home/ai/.local/share
    /run/wrappers/bin/sudo ${pkgs.rsync}/bin/rsync -a --delete --exclude .git --exclude .worktrees --exclude node_modules "$source_config_dir/" "$ai_config_dir/"
    /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chown -R ai:ai "$ai_config_dir"

    exec /run/wrappers/bin/sudo \
      --preserve-env=COLORTERM,DBUS_SESSION_BUS_ADDRESS,DESKTOP_SESSION,DISPLAY,LANG,LC_ALL,LC_CTYPE,PATH,SSH_AUTH_SOCK,TERM,WAYLAND_DISPLAY,XAUTHORITY,XDG_CURRENT_DESKTOP,XDG_RUNTIME_DIR \
      -H -u ai \
      ${pkgs.coreutils}/bin/env \
      PATH="$PATH" \
      HOME=/home/ai \
      USER=ai \
      LOGNAME=ai \
      SHELL=${ai-preserved-shell}/bin/ai-preserved-shell \
      XDG_CONFIG_HOME=/home/ai/.config \
      XDG_CACHE_HOME=/home/ai/.cache \
      XDG_DATA_HOME=/home/ai/.local/share \
      BROWSER=${pkgs.xdg-utils}/bin/xdg-open \
      OPENCODE_CONFIG_DIR=/home/ai/.local/share/opencode-config \
      ${pkgs.unstable.opencode}/bin/opencode "$@"
  '';

  ai-mcp-auth = pkgs.writeShellScriptBin "ai-mcp-auth" ''
    set -euo pipefail
    exec ${ai-opencode}/bin/ai-opencode mcp auth "$@"
  '';

  ai-grant = pkgs.writeShellScriptBin "ai-grant" ''
    set -euo pipefail

    usage() {
      echo "Usage: ai-grant [--readonly] <directory>" >&2
      exit 1
    }

    readonly=false

    while [ $# -gt 0 ]; do
      case "$1" in
        --readonly|-r)
          readonly=true
          shift
          ;;
        --help|-h)
          usage
          ;;
        --)
          shift
          break
          ;;
        -*)
          echo "error: unknown option: $1" >&2
          usage
          ;;
        *)
          break
          ;;
      esac
    done

    [ $# -eq 1 ] || usage

    target=$(${pkgs.coreutils}/bin/realpath "$1")
    home_dir=$(${pkgs.coreutils}/bin/realpath "$HOME")

    ensure_traverse_acl() {
      path="$1"
      while [ "$path" != "/" ] && [ "$path" != "$target" ]; do
        case "$path" in
          "$home_dir"|/home)
            acl="--x"
            ;;
          "$home_dir"/*)
            acl="r-x"
            ;;
          *)
            acl="--x"
            ;;
        esac
        /run/wrappers/bin/sudo /run/current-system/sw/bin/setfacl -m "u:ai:$acl" "$path"
        path=$(${pkgs.coreutils}/bin/dirname "$path")
      done
    }

    if [ ! -d "$target" ]; then
      echo "error: directory does not exist: $target" >&2
      exit 1
    fi

    case "$target" in
      /|/home|"$home_dir")
        echo "error: refusing to grant broad home/system directories" >&2
        exit 1
        ;;
      "$home_dir"/*)
        ;;
      *)
        echo "error: only directories inside $home_dir can be granted" >&2
        exit 1
        ;;
    esac

    ensure_traverse_acl "$(${pkgs.coreutils}/bin/dirname "$target")"

    /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chgrp -R devs "$target"

    if [ "$readonly" = true ]; then
      /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chmod -R g+rX "$target"
      /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chmod -R g-w "$target"
      echo "Granted ai read-only access to: $target"
    else
      /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chmod -R g+rwX "$target"
      /run/wrappers/bin/sudo ${pkgs.findutils}/bin/find "$target" -type d -exec ${pkgs.coreutils}/bin/chmod g+rwX {} +
      echo "Granted ai read-write access to: $target"
    fi
  '';

  ai-revoke = pkgs.writeShellScriptBin "ai-revoke" ''
    set -euo pipefail

    usage() {
      echo "Usage: ai-revoke <directory>" >&2
      exit 1
    }

    [ $# -eq 1 ] || usage

    target=$(${pkgs.coreutils}/bin/realpath "$1")
    home_dir=$(${pkgs.coreutils}/bin/realpath "$HOME")
    primary_group=$(${pkgs.coreutils}/bin/id -gn)

    if [ ! -d "$target" ]; then
      echo "error: directory does not exist: $target" >&2
      exit 1
    fi

    case "$target" in
      /|/home|"$home_dir")
        echo "error: refusing to revoke broad home/system directories" >&2
        exit 1
        ;;
      "$home_dir"/*)
        ;;
      *)
        echo "error: only directories inside $home_dir can be revoked" >&2
        exit 1
        ;;
    esac

    /run/wrappers/bin/sudo ${pkgs.findutils}/bin/find "$target" -type d -exec ${pkgs.coreutils}/bin/chmod g-rwX {} +
    /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chmod -R g-rwX "$target"
    /run/wrappers/bin/sudo ${pkgs.coreutils}/bin/chgrp -R "$primary_group" "$target"

    echo "Revoked ai access to: $target"
  '';

  ai-reset-traverse-acls = pkgs.writeShellScriptBin "ai-reset-traverse-acls" ''
    set -euo pipefail

    usage() {
      echo "Usage: ai-reset-traverse-acls [directory]" >&2
      exit 1
    }

    if [ $# -gt 1 ]; then
      usage
    fi

    home_dir=$(${pkgs.coreutils}/bin/realpath "$HOME")
    target=''${1:-$home_dir}
    target=$(${pkgs.coreutils}/bin/realpath "$target")

    case "$target" in
      /|/home)
        echo "error: refusing to touch broad system directories" >&2
        exit 1
        ;;
      "$home_dir"|"$home_dir"/*)
        ;;
      *)
        echo "error: only directories inside $home_dir can be cleaned" >&2
        exit 1
        ;;
    esac

    /run/wrappers/bin/sudo ${pkgs.findutils}/bin/find "$target" -type d -exec /run/current-system/sw/bin/setfacl -x u:ai {} + 2>/dev/null || true

    echo "Removed ai traverse ACLs under: $target"
  '';

  shellAliases = {
    gv = "nvim -c ':G | :only' .";
    gf = "git fetch";
    ga = "git add";
    gba = "git branch -r --no-merged $(git branch -l main master --format '%(refname:short)' | head -n 1)";
    gc = "git commit";
    gco = "git checkout";
    gcom = "git checkout main || git checkout master && git pull --no-rebase";
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
    pkgs.bc # calculator for the terminal
    pkgs.tree
    pkgs.watch
    pkgs.qtpass
    pkgs.gawk
    pkgs.unzip
    pkgs.zip
    pkgs.mirrord
    pkgs.bruno
    pkgs.unstable.opencode
    pkgs.openspec
    pkgs.unstable.opencode-desktop

    jira-cli
    jira-select-project
    jira-select-issue
    jira-view-issue
    jira-issue-create
    jira-issue-create-in-projects
    jira-branch-from-issue
    dpi-toggle
    git-active-branches
    ai-shell
    ai-preserved-shell
    ai-opencode
    ai-mcp-auth
    ai-grant
    ai-revoke
    ai-reset-traverse-acls

    # Node is required for Copilot.vim
    pkgs.nodejs
  ] ++ (lib.optionals isDarwin [
    # This is automatically setup on Linux
    pkgs.cachix
    pkgs.tailscale
    pkgs.iterm2
    pkgs.catimg
    pkgs.sshfs
    pkgs.vifm
    pkgs.xz
    pkgs.vpnutil

    (pkgs.writeShellScriptBin "mount-emision" ''
      pgrep -lf sshfs | tee /dev/stderr | awk '{print $1}' | xargs sudo kill -9
      diskutil unmount force $HOME/emision
      sshfs moisesnessim@172.16.79.89:/home/moisesnessim $HOME/emision
      ''
    )


  ]) ++ (lib.optionals isLinux [
    pkgs.vifm-full
    pkgs.chromium
    pkgs.firefox
    pkgs.zathura
    pkgs.autocutsel
    pkgs.libnotify
    pkgs.mpv
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
    AUDIO_PLAYER = "${pkgs.mpv}/bin/mpv";
  };


  home.file = {
      ".gdbinit".source = ./gdbinit;
      ".inputrc".source = ./inputrc;
  } // lib.optionalAttrs isDarwin {
      # ".skhdrc".source = ./skhdrc;
      ".aerospace.toml".source = ./aerospace.toml;
  };

  xdg.configFile = {
      "i3/config".source = ./i3;
      "devtty/config".source = ./devtty;

      # Rectangle.app. This has to be imported manually using the app.
      "rectangle/RectangleConfig.json".source = ./RectangleConfig.json;

  } // lib.optionalAttrs isDarwin {
      "vifm/vifmrc".source = ./vifmrc;
      "karabiner/karabiner.json".source = ./karabiner/karabiner.json;
      "karabiner/assets/complex_modifications/custom-capslock.json".source = ./karabiner/assets/complex_modifications/custom-capslock.json;
  };

  xdg.mimeApps = {
    enable = isLinux;
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

  programs.rofi.pass.enable = isLinux;

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
      push.autoSetupRemote = true;
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
      vimPlugins.which-key-nvim
      customVim.vim-copilot
      customVim.vim-cue
      customVim.vim-fish
      customVim.vim-fugitive
      customVim.vim-glsl
      customVim.vim-pgsql
      customVim.vim-tla
      customVim.pigeon
      customVim.AfterColors

      customVim.vim-devicons
      customVim.vim-nord
      customVim.nvim-lspconfig
      # customVim.nvim-plenary # required for telescope
      vimPlugins.plenary-nvim  # required for telescope
      # customVim.nvim-telescope
      vimPlugins.telescope-nvim
      # customVim.nvim-treesitter
      # customVim.nvim-treesitter-playground
      # customVim.nvim-treesitter-textobjects
      vimPlugins.nvim-treesitter.withAllGrammars


      customVim.nvim-magma
      customVim.vifm-vim
      # customVim.toggleterm
      vimPlugins.toggleterm-nvim
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

      customVim.vim-misc

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

        # https://github.com/qutebrowser/qutebrowser/issues/7427
        config.set("content.headers.user_agent",
                   "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
                   "accounts.google.com")

        config.bind('<z><l>', 'spawn --userscript qute-pass ${args}')
        config.bind('<z><u><l>', 'spawn --userscript qute-pass ${args} --username-only')
        config.bind('<z><p><l>', 'spawn --userscript qute-pass ${args} --password-only')
        config.bind('<z><o><l>', 'spawn --userscript qute-pass ${args} --otp-only')

        config.bind('ca', 'set -t content.javascript.clipboard access ;; cmd-later 10s set -p content.javascript.clipboard none')

      '';
  };

  services.gpg-agent = {
    enable = isLinux;
    # deprecated
    pinentry.package = pkgs.pinentry-gtk2;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  services.picom.enable = isLinux;

  services.safeeyes.enable = isLinux;
  services.snixembed = {
    enable = isLinux;

    beforeUnits = [
      # https://github.com/slgobinath/SafeEyes/wiki/How-to-install-backend-for-Safe-Eyes-tray-icon
      "safeeyes.service"
    ];
  };

  services.copyq = {
    enable = isLinux;
  };

  services.dunst.enable = isLinux;

  systemd.user.services.low-memory-notify = lib.mkIf isLinux {
    Unit = {
      Description = "Notify when available memory is low";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${low-memory-notify}/bin/low-memory-notify";
    };
  };

  systemd.user.timers.low-memory-notify = lib.mkIf isLinux {
    Unit = {
      Description = "Check available memory periodically";
    };

    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "1m";
      Unit = "low-memory-notify.service";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
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
