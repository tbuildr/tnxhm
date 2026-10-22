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

      # devenv's hook-spawned subshell installs __devenv_exit_on_cd_out
      # into PROMPT_COMMAND *after* ~/.bashrc, but once ble.sh is attached
      # it runs prompt hooks itself and that late edit never fires, so the
      # subshell never exits on cd-out. Register the check via ble's PRECMD
      # hook instead. The function only exists in hook-spawned shells
      # (devenv's rcfile defines it after this runs), so resolve it at
      # prompt time. Verified with devenv 2.4.0 + ble.sh 0.4.0-devel3.
      __tom_devenv_exit_check() {
        declare -F __devenv_exit_on_cd_out >/dev/null && __devenv_exit_on_cd_out
      }
      if declare -F blehook >/dev/null; then
        blehook PRECMD+=__tom_devenv_exit_check
      fi
    '';
  };
}
