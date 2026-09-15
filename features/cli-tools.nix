{...}: {
  flake.homeModules.cli-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      bat
      eza
      fd
      herdr
      lazydocker
      kind
      kubectl
      kubernetes-helm
      k9s
      nmap
      rclone
      ripgrep
      swappy
      tmux
      wtype
    ];
  };
}
