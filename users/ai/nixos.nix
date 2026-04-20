{ pkgs, ... }:

{
  users.groups.ai = {};

  users.users.ai = {
    group = "ai";
    isNormalUser = true;
    home = "/home/ai";
    createHome = true;
    extraGroups = [ "devs" ];
    shell = pkgs.bash;
  };

  home-manager.users.ai = import ./home-manager.nix;
}
