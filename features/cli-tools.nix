{...}: {
  flake.homeModules.cli-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      bat
      eza
      fd
      lazydocker
      rclone
      ripgrep
      tmux
      herdr
      wtype
    ];
  };
}
