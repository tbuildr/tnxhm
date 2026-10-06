{...}: {
  flake.homeModules.cli-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      bat
      butane
      eza
      fd
      herdr
      lazydocker
      kind
      kubectl
      kubernetes-helm
      k9s
      nodejs_24
      nmap
      rclone
      ripgrep
      shellcheck
      swappy
      tmux
      wtype
    ];
  };
}
