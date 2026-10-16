{
  inputs,
  moduleWithSystem,
  self,
  ...
}: let
  # configs/fastfetch/config.json is the single source of truth for layout
  # and the Matrix colour scheme (display.constants $3–$14).
  fastfetchSettings = builtins.fromJSON (
    builtins.readFile (
      self + /configs/fastfetch/config.json
    )
  );
in {
  # Install the wrapped Fastfetch package for the current system.
  flake.homeModules.fastfetch = moduleWithSystem (
    {self', ...}: {
      home.packages = [
        self'.packages.fastfetch
      ];
    }
  );

  # Build Fastfetch with its configuration embedded in the package.
  perSystem = {pkgs, ...}: {
    packages.fastfetch = inputs.wrappers.wrappers.fastfetch.wrap {
      inherit pkgs;

      settings = fastfetchSettings;
    };
  };
}
