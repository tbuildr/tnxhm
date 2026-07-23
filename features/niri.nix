{
  self,
  lib,
  ...
}: {
  flake.homeModules.niri = {
    xdg.configFile."niri" = {
      source = "${self}/dotfiles/niri";
      recursive = true;
    };

    home.activation.validateNiriConfig = lib.hm.dag.entryBefore ["writeBoundary"] ''
      if [[ ! -x /usr/bin/niri ]]; then
        echo "Fedora Niri is missing at /usr/bin/niri" >&2
        exit 1
      fi

      echo "Validating Niri configuration..."
      /usr/bin/niri validate \
        -c "${self}/dotfiles/niri/config.kdl"
    '';
  };

  perSystem = {pkgs, ...}: {
    apps.niri-validate = {
      type = "app";

      program = "${
        pkgs.writeShellApplication {
          name = "niri-validate";

          text = ''
            if [[ ! -x /usr/bin/niri ]]; then
              echo "Fedora Niri is missing at /usr/bin/niri" >&2
              exit 1
            fi

            exec /usr/bin/niri validate \
              -c "${self}/dotfiles/niri/config.kdl"
          '';
        }
      }/bin/niri-validate";

      meta.description = "Validate the managed KDL using Fedora's Niri";
    };
  };
}
