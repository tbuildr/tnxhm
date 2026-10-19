{...}: {
  /*
  nix-output-monitor (nom) — presents Nix builds as a readable dependency tree
                             and supports commands such as nom build, nom shell and nom develop.
  nix-tree                 — interactively examines the dependency graph and closure behind a package
                             useful when investigating why something consumes significant store space.
  alejandra                — formats Nix files.
  statix                   — identifies questionable or unnecessary Nix expressions.
  deadnix                  — identifies unused Nix code.
  */

  flake.homeModules.nix-tools = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = with pkgs; [
      alejandra
      deadnix
      nix-output-monitor
      nix-tree
      statix
    ];

    programs.nh = {
      enable = true;
      flake = lib.mkDefault "$HOME/.config/home-manager";
    };

    programs.nix-index = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.nix-index-database.comma.enable = true;
  };

  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
