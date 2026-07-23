{
  config,
  inputs,
  ...
}: let
  publicHomeModule = {
    imports = [
      # External Home Manager modules.
      inputs.nix-index-database.homeModules.default
      inputs.nvf.homeManagerModules.nvf

      # Reusable public features.
      config.flake.homeModules.btop
      config.flake.homeModules.cli-tools
      config.flake.homeModules.devenv
      config.flake.homeModules.editor
      config.flake.homeModules.fastfetch
      config.flake.homeModules.fonts
      config.flake.homeModules.kitty
      config.flake.homeModules.lazygit
      config.flake.homeModules.niri
      config.flake.homeModules.nix-tools
      config.flake.homeModules.portals
      config.flake.homeModules.shell
      config.flake.homeModules.ssh
      config.flake.homeModules.toolbox
      config.flake.homeModules.yazi
    ];
  };
in {
  # Reusable module imported by a separate user-specific wrapper.
  flake.homeModules.default = publicHomeModule;
}
