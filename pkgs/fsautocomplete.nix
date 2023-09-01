{ buildDotnetGlobalTool, lib }:

buildDotnetGlobalTool {
  pname = "fsautocomplete";
  version = "0.62.0";

  nugetSha256 = "sha256-p5A8WURcGbI8kgEVpvTYQnbcEGoIExPYA3FAR+bPM90=";

  meta = with lib; {
    homepage = "https://github.com/fsharp/FsAutoComplete";
    changelog = "https://github.com/fsharp/FsAutoComplete/releases";
    license = licenses.apsl20;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
