{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix)
  ];

  system.activationScripts.preActivation.text = lib.mkAfter ''
    if [ -x "${config.homebrew.brewPrefix}/brew" ]; then
      for tap in nikitabobko/tap FelixKratz/formulae; do
        sudo --user=moisesnessim --set-home \
          "${config.homebrew.brewPrefix}/brew" trust --tap "$tap"
      done
    fi
  '';

  homebrew = {
    enable = true;
    casks  = [
      "aerospace"
      # "alt-tab" # not free
      # "1password"
      # "alfred"
      # "cleanshot"
      # "discord"
      "google-chrome"
      "hammerspoon"
      # "imageoptim"
      # "istat-menus"
      # "monodraw"
      # "rectangle"
      # "screenflow"
      "slack"
      "spotify"
      "dbeaver-community"
      "maccy"
      "whatsapp"
      "finetune"
    ];
    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];
    brews = [
      "libvterm"
      "m1ddc"
      "cloudflared"
      "sketchybar"
      {
        name = "container";
      }
      {
        name = "container-compose";
      }
    ];
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.moisesnessim = {
    home = "/Users/moisesnessim";
    shell = pkgs.fish;
  };
}
