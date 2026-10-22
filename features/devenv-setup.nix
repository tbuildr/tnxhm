{...}: {
  flake.homeModules.devenv-setup = {
    pkgs,
    lib,
    ...
  }: {
    # Install the Devenv CLI for the user.
    home.packages = [pkgs.devenv];

    # Native devenv shell hook: activates a project's devenv on cd into
    # it, deactivates on cd out. Replaces direnv + per-project .envrc;
    # per-project env now lives entirely in each devenv.nix.

    # Fish: dormant unless programs.fish.enable is set elsewhere; kept so
    # a temporary switch back to fish gets the hook automatically.
    programs.fish.interactiveShellInit = lib.mkAfter ''
      devenv hook fish | source
    '';

    # Bash: must land before ble-attach (mkOrder 2500 in bash.nix) so the
    # hook makes it into PROMPT_COMMAND — lib.mkAfter is order 1500.
    programs.bash.initExtra = lib.mkAfter ''
      eval "$(devenv hook bash)"
    '';
  };
}
