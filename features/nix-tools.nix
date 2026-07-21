{...}: {
  flake.homeModules.nix-tools = {
    programs.nh = {
      enable = true;
      flake = "$HOME/.config/home-manager";
    };

    programs.nix-index = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.nix-index-database.comma.enable = true;
  };
}
