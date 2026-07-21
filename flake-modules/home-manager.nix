{
  config,
  inputs,
  withSystem,
  ...
}: {
  flake.homeConfigurations.tom = withSystem "x86_64-linux" ({pkgs, ...}:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [
        inputs.nix-index-database.homeModules.default
        inputs.nvf.homeManagerModules.nvf

        config.flake.homeModules.profile
        config.flake.homeModules.shell
        config.flake.homeModules.ssh
        config.flake.homeModules.terminal
        config.flake.homeModules.yazi
        config.flake.homeModules.niri
        config.flake.homeModules.portals
        config.flake.homeModules.nix-tools
        config.flake.homeModules.btop
        config.flake.homeModules.lazygit

        ../home-modules/devenv.nix
        ../home-modules/nvf.nix
        ../home-modules/packages.nix
        ../home-modules/toolbox.nix
      ];
    });
}
