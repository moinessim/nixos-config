{ pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];

  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.moisesnessim = {
    isNormalUser = true;
    home = "/home/moisesnessim";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
      hashedPassword = "$y$j9T$TI6TlM/lCf7qQxK0IOuV00$ZX7F24S6jhxGbku4gAvbbOvx2CN7Vt2hW0Wdm0GZu9C";
      openssh.authorizedKeys.keys = [
       "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDC0oN+Cqg6D0BEdPIaHYMmQf6kPf+WK7PTUHeT4c4jzZUuJK4M3aP4tTkCmj36rabH2rF/wInZrDwUr64+3jEF6Dsd9SUw08Kupz8oRl7baZE1U5aB/iymp6bUK+4bUREJaBmlTVZhQIP82Z7s2rPYBNI7kLMO+nK4+4Ahx0N3s3tQlylgIug4AIzG6XPe5TUZrMGFdvp5bew6/HkxbXuIopsuItU7R2VQbsSDFZM0HKjMt88RG5oxnF304UI4BPEP7M75G43F0+zPCpyyIQhR0r8wWfCxDcergippBxYScWtbjDvhU2T3m4wEHrfnmKFiNlT4JLXam5dTOqshxzpJ moisesnessim@admins-MacBook-Pro.local"
      ];
  };

  security.pki.certificateFiles = [
    ./topmanage-ca.pem
  ];

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix)
  ];

  systemd.user.services.autocutsel-clipboard = {
    enable = true;
    description = "Clipboard sync: CLIPBOARD <-→ BUFFER-CUT";
    wantedBy = [ "default.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.autocutsel}/bin/autocutsel";
      Restart = "always";
    };
  };

  systemd.user.services.autocutsel-primary = {
    enable = true;
    description = "Clipboard sync: PRIMARY <-→ BUFFER-CUT";
    wantedBy = [ "default.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY";
      Restart = "always";
    };
  };

}
