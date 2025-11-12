self: super: with super;
{
    vpnutil = stdenv.mkDerivation {
      name = "vpnutil";
      src = fetchzip {
            url = "https://github.com/Timac/VPNStatus/releases/download/1.4/vpnutil.zip";
            sha256 = "sha256-a5vggLBTE6u3b5UvEAcUAlsqysqZDRFYXBdEWCTmhCo=";
          };
      installPhase = ''
        mkdir -p $out/bin
        cp -v vpnutil $out/bin/vpnutil
        '';
      meta = {
        homepage = "https://blog.timac.org/2018/0719-vpnstatus/";
        description = ''Command line tool similar to scutil that can start and stop a VPN service from the Terminal. It also works with IKEv2 VPN services, something not supported by the built-in scutil'';
        license = lib.licenses.mit;
        platforms = lib.platforms.darwin;
      };
    };
}
