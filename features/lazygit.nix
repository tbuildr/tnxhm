{
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.homeModules.lazygit = moduleWithSystem (
    {self', ...}: {
      home.packages = [
        self'.packages.lazygit
      ];
    }
  );

  perSystem = {pkgs, ...}: let
    configFile = pkgs.writeText "lazygit-config.yml" ''
      gui:
        nerdFontsVersion: "3"

      customCommands:
        - key: 'p'
          context: 'global'
          command: 'git pull --recurse-submodules'
          loadingText: 'Pulling with submodules'
          output: 'log'

        - key: '<c-p>'
          context: 'global'
          command: 'git pull'
          loadingText: 'Pulling remote repository'
          output: 'log'
    '';
  in {
    packages.lazygit = inputs.wrappers.lib.wrapPackage (
      {...}: {
        # This is the pkgs value from the outer perSystem function.
        inherit pkgs;

        package = pkgs.lazygit;

        flags = {
          "--use-config-file" = configFile;
        };
      }
    );
  };
}
