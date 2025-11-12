{ spacebar, fetchFromGitHub }:
spacebar.overrideAttrs (
      o: rec {

        version = "1.4.0";

        src = fetchFromGitHub {
          owner = "cmacrae";
          repo = "spacebar";
          rev = "v${version}";
          sha256 = "sha256-4LiG43kPZtsm7SQ/28RaGMpYsDshCaGvc1mouPG3jFM=";
        };
      }
    )
