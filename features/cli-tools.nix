{...}: {
  flake.homeModules.cli-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      age
      age-plugin-yubikey
      bat
      butane
      eza
      fd
      gitleaks
      lazydocker
      kind
      kubectl
      kubernetes-helm
      k9s
      nodejs_24
      nmap
      passage
      rclone
      ripgrep
      shellcheck
      swappy
      tmux
      uv
      wtype
    ];
  };
}
