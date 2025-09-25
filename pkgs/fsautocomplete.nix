{ fsautocomplete, writeShellScriptBin, ... }:
{
  fsautocomplete-local-or-nix =
      writeShellScriptBin "fsautocomplete" ''
        if command -v dotnet >/dev/null && dotnet tool run fsautocomplete --version >/dev/null 2>/dev/null;
        then
          exec dotnet tool run fsautocomplete "$@"
        else
          exec "${fsautocomplete}/bin/fsautocomplete" "$@"
        fi
    '';
  inherit fsautocomplete;
}
