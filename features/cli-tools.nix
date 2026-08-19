{...}: {
  flake.homeModules.cli-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      bat
      eza
      fd
      lazydocker
      nerdctl
      rclone
      ripgrep
      tmux
      herdr
      wtype
    ];
  };
}
