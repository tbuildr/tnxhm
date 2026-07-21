{...}: {
  flake.homeModules.ssh = {pkgs, ...}: let
    sshAskpass = pkgs.writeShellScript "ssh-askpass-wrapper" ''
      eval export $(
        ${pkgs.systemd}/bin/systemctl --user show-environment |
          ${pkgs.gnugrep}/bin/grep \
            -E '^(DISPLAY|WAYLAND_DISPLAY|XAUTHORITY|DBUS_SESSION_BUS_ADDRESS)='
      )

      exec ${pkgs.zenity}/bin/zenity \
        --password \
        --title="YubiKey FIDO2" \
        --text="$1"
    '';
  in {
    # Cache the local SSH key-stub passphrase for up to 30 days.
    # YubiKey PIN and touch requirements remain enabled.
    services.ssh-agent = {
      enable = true;
      defaultMaximumIdentityLifetime = 2592000;
    };

    systemd.user.services.ssh-agent.Service.Environment = [
      "SSH_ASKPASS=${sshAskpass}"
      "SSH_ASKPASS_REQUIRE=force"
    ];
  };
}
