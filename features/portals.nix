{...}: {
  flake.homeModules.portals = {
    xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
      [preferred]
      default=gnome;gtk;
      org.freedesktop.impl.portal.Access=gtk;
      org.freedesktop.impl.portal.Notification=gtk;
      org.freedesktop.impl.portal.Secret=oo7-portal;
      org.freedesktop.impl.portal.FileChooser=gtk;
    '';
  };
}
