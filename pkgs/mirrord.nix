# with import <nixpkgs> {};
{stdenv, fetchurl}:

with(
  if stdenv.isDarwin
  then { OS = "mac"; ARCH = "universal"; }
  else { OS = "linux"; ARCH = stdenv.hostPlatform.uname.processor; }
);
stdenv.mkDerivation rec {
    pname = "mirrord";
    version = "3.115.1";
    src = fetchurl {
      url = "https://github.com/metalbear-co/mirrord/releases/download/${version}/mirrord_${OS}_${ARCH}";
      sha256 = "sha256-AJ1z/rv+xLKtYirpFPvLeQxLvjcnxPgWXWuj96ONlyQ=";
    };
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/mirrord
      chmod +x $out/bin/mirrord
    '';
  }
