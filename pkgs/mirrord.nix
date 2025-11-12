# with import <nixpkgs> {};
{stdenv, fetchurl}:

with(
  if stdenv.isDarwin
  then {
    OS = "mac";
    ARCH = "universal";
    sha256 = "sha256-9q1S61x7jmRU14m/V3bMaSLyqIDeRyUUDf1bKE4pxIY=";
  }
  else {
    OS = "linux";
    ARCH = stdenv.hostPlatform.uname.processor;
    sha256 = "sha256-AJ1z/rv+xLKtYirpFPvLeQxLvjcnxPgWXWuj96ONlyQ=";
  }
);
stdenv.mkDerivation rec {
    pname = "mirrord";
    version = "3.115.1";
    src = fetchurl {
      url = "https://github.com/metalbear-co/mirrord/releases/download/${version}/mirrord_${OS}_${ARCH}";
      inherit sha256;
    };
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/mirrord
      chmod +x $out/bin/mirrord
    '';
  }
