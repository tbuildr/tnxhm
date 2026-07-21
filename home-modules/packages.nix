{pkgs, ...}: {
  home.packages = with pkgs; [
    /*
    nix-output-monitor  nom — presents Nix builds as a readable dependency tree and supports commands such as nom build, nom shell and nom develop.
    nix-tree — interactively examines the dependency graph and closure behind a package; useful when investigating why something consumes significant store space.
    alejandra — formats Nix files.
    statix — identifies questionable or unnecessary Nix expressions.
    deadnix — identifies unused Nix code.
    */
    alejandra
    bat
    deadnix
    eza
    fd
    lazydocker
    neovim
    nerd-fonts.jetbrains-mono
    nix-output-monitor
    nix-tree
    rclone
    ripgrep
    statix
    tmux
    wtype
    yazi
    zoxide
  ];
  fonts.fontconfig.enable = true;
}
