{...}: {
  flake.homeModules.fonts = {pkgs, ...}: {
    home.packages = [
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.meslo-lg
    ];

    fonts.fontconfig.enable = true;
  };
}
