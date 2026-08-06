{...}: {
  flake.homeModules.ollama = {
    config,
    lib,
    ...
  }: let
    cfg = config.services.ollama-rootless;

    backendSettings = {
      rocm = {
        image = "docker.io/ollama/ollama:rocm";
        extraLines = ''
          AddDevice=/dev/kfd
          AddDevice=/dev/dri
          PodmanArgs=--ipc=host
        '';
      };
      cuda = {
        image = "docker.io/ollama/ollama:latest";
        extraLines = ''
          PodmanArgs=--device nvidia.com/gpu=all
        '';
      };
    };

    selected = backendSettings.${cfg.backend};
  in {
    options.services.ollama-rootless = {
      enable = lib.mkEnableOption "rootless Ollama podman quadlet";

      backend = lib.mkOption {
        type = lib.types.enum ["rocm" "cuda"];
        default = "rocm";
        description = "GPU backend: rocm (AMD) or cuda (NVIDIA).";
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.ollama-rootless";
        description = "Host directory bind-mounted as the container's model/data store.";
      };
    };

    config = lib.mkIf cfg.enable {
      xdg.configFile."containers/systemd/ollama-rootless.container".text = ''
        [Unit]
        Description=Ollama (${cfg.backend}, rootless)

        [Container]
        Environment=OLLAMA_KEEP_ALIVE=5m
        Image=${selected.image}
        ContainerName=ollama-rootless
        PublishPort=127.0.0.1:11434:11434
        Volume=${cfg.dataDir}:/root/.ollama:Z
        ${selected.extraLines}

        [Service]
        Restart=on-failure

        [Install]
        WantedBy=default.target
      '';

      home.activation.ensureOllamaDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "${cfg.dataDir}"
      '';
    };
  };
}
