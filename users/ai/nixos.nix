{ pkgs, ... }:

{
  users.users.ai = {
    group = "devs";
    isNormalUser = true;
    home = "/home/ai";
    createHome = true;
    shell = pkgs.bash;
  };

  home-manager.users.ai = import ./home-manager.nix;
}
