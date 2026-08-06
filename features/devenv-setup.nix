{...}: {
  flake.homeModules.devenv-setup = {
    pkgs,
    lib,
    ...
  }: {
    # Install the Devenv CLI for the user.
    home.packages = [
      pkgs.devenv
    ];

    # Automatically activate trusted Devenv projects.
    programs.fish.interactiveShellInit = lib.mkAfter ''
      devenv hook fish | source
    '';
  };
}
