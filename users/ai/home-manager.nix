{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  home.packages = [
    pkgs.unstable.opencode
    pkgs.openspec
    pkgs.xdg-utils
  ];

  home.sessionVariables = {
    BROWSER = "${pkgs.xdg-utils}/bin/xdg-open";
    UMASK = "0002";
  };

  programs.git = {
    enable = true;
    settings = {
        user.name = "Moises Nessim";
        user.email = "moises.nessim@topmanage.com";
        alias = {
          cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop\\|main' | xargs -n 1 -r git branch -d";
          prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
          root = "rev-parse --show-toplevel";
        };
        safe.directory = "/home/moisesnessim/*";
    };
    hooks = {
        prepare-commit-msg = ../moisesnessim/prepare-commit-msg;
    };
  };
}
