{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.unstable.opencode
    pkgs.openspec
    pkgs.xdg-utils
    pkgs.firefox
  ];

  home.sessionVariables = {
    BROWSER = "${pkgs.xdg-utils}/bin/xdg-open";
    OPENCODE_CONFIG_DIR = "/home/ai/.local/share/opencode-config";
  };
}
