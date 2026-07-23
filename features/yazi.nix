{self, ...}: {
  flake.homeModules.yazi = {pkgs, ...}: {
    home.packages = [
      pkgs.yazi
    ];

    xdg.configFile = {
      "yazi/init.lua".source =
        self + /dotfiles/yazi/init.lua;

      "yazi/yazi.toml".source =
        self + /dotfiles/yazi/yazi.toml;
    };
  };
}
