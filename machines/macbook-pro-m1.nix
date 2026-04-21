{  pkgs, ... }:
let

  EnvironmentVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  KeepAlive = pkgs.lib.mkForce { PathState."/nix/store" = true; };

in {
  # Keep in async with vm-shared.nix. (todo: pull this out into a file)
  nix = {
    # Auto upgrade nix package and the daemon service.
    package = pkgs.nixVersions.latest;
    # We need to enable flakes
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    # public binary cache that I use for all my derivations. You can keep
    # this, use your own, or toss it. Its typically safe to use a binary cache
    # since the data inside is checksummed.
    settings = {
      trusted-users = [ "moisesnessim" ];
      substituters = [
        "https://mitchellh-nixos-config.cachix.org"
        "https://cache.nixos.org"
        "https://cache.dhall-lang.org"
        "https://dhall.cachix.org"
        "s3://nix-binary-cache?scheme=https&endpoint=object-storage.topmanage.cloud"
      ];

      trusted-public-keys = [
        "mitchellh-nixos-config.cachix.org-1:bjEbXJyLrL1HZZHBbO4QALnI5faYZppzkU4D2s0G8RQ="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.dhall-lang.org:I9/H18WHd60olG5GsIjolp7CtepSgJmM2CsO813VTmM="
        "dhall.cachix.org-1:8laGciue2JBwD49ICFtg+cIF8ddDaW7OFBjDb/dHEAo="
        "my-cache-1:0UcKGgS+Ia7LQV9v/rV7YdcP79yS9YIaX8GpzKkUXJg="
      ];
    };
  };

  # zsh is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    # Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    # End Nix
    '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    # Nix
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix
    '';

  environment.shells = with pkgs; [ bashInteractive zsh fish ];
  environment.systemPackages = with pkgs; [
    cachix
  ];

  services.spacebar.enable = true;


  services.spacebar.package = import ../pkgs/spacebar.nix { inherit (pkgs) spacebar fetchFromGitHub; };
  services.spacebar.config =
    let
      spacebar_height = 20;
      clock_icon = "";
    in {
    position           = "bottom";
    height             = spacebar_height;
    spacing_left       = 25;
    spacing_right      = 15;
    text_font          = ''"Fira Code:Medium:13.0"'';
    icon_font          = ''"Font Awesome 5 Free:Solid:13.0"'';
    background_color   = "0xff000000";
    foreground_color   = "0xffFFFFFF";
    space_icon_color   = "0xffFFFF00";
    power_icon_color   = "0xffcd950c";
    battery_icon_color = "0xffd75f5f";
    dnd_icon_color     = "0xffa8a8a8";
    clock_icon_color   = "0xffa8a8a8";
    space_icon_strip   = "1 2 3 4 5 6 7 8 9 10";
    power_icon_strip   = " ";
    space_icon         = "";
    inherit clock_icon;
    dnd_icon           = "";
    clock_format       = ''"%a %b %e  %I:%M %p"'';
  };

  launchd.user.agents.spacebar.serviceConfig = {
    inherit KeepAlive EnvironmentVariables;
  };

  services.skhd.enable = true;
  services.skhd.skhdConfig = builtins.readFile ../users/moisesnessim/skhdrc;
  launchd.user.agents.skhd.serviceConfig = {
    inherit EnvironmentVariables KeepAlive;
    RunAtLoad = true;
  };

  fonts = {
    # fontDir.enable = true;
    packages = with pkgs; [
      powerline-fonts
      fira-code
      fira-code-symbols
      fira-mono
      font-awesome_5
      dejavu_fonts
    ];
  };

  system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = 3.0 ;

  system.primaryUser = "moisesnessim";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
