{...}: {
  flake.homeModules.host-tools = {
    pkgs,
    lib,
    ...
  }: let
    clamscan-host = pkgs.writeShellApplication {
      name = "clamscan-host";
      text = builtins.readFile ./host-tools/clamscan-host.sh;
    };
    clamscan-host-full = pkgs.writeShellApplication {
      name = "clamscan-host-full";
      text = ''exec sudo ${lib.getExe clamscan-host} "$@"'';
    };
    podman-image-sizes = pkgs.writeShellApplication {
      name = "podman-image-sizes";
      text = builtins.readFile ./host-tools/podman-image-sizes.sh;
    };
  in {
    home.packages = [clamscan-host clamscan-host-full podman-image-sizes];
  };
}
