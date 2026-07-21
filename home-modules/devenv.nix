{
  pkgs,
  lib,
  ...
}: {
  # Install the devenv command globally for the user.
  home.packages = [
    pkgs.devenv
  ];

  # Automatically activate trusted devenv projects when entering them.
  programs.fish.interactiveShellInit = lib.mkAfter ''
    devenv hook fish | source
  '';
}
