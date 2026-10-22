{...}: {
  flake.homeModules.agent-launchers = {
    pkgs,
    lib,
    ...
  }: let
    # One launcher per agent, all running the shared agents-sandbox image
    # (built by `bsbx` in ~/Projects/tdev). Installed from the read-only
    # Nix store on purpose: an agent whose workspace is tdev can edit
    # anything in it, so nothing the host executes may live there.
    #
    # podman deliberately NOT in runtimeInputs — use the host's rootless
    # podman (its storage, registries and SELinux policy), not a Nix one.
    mkLauncher = {
      name,
      agent,
      hostNetwork ? true,
      env ? {},
      # [ { sub = "<dir under the agent's state root>"; dest = "<container path>"; } ]
      mounts,
    }:
      pkgs.writeShellApplication {
        inherit name;
        text = ''
          state_root="''${XDG_STATE_HOME:-$HOME/.local/state}"
          state="$state_root/agents/${agent}"
          mkdir -p "$state"

          # Compare physical paths: on Fedora Atomic /home -> /var/home, so
          # a $PWD reached via /home/tom/... would never match $HOME.
          ws="$(pwd -P)"
          home="$(cd "$HOME" && pwd -P)"
          real_state_root="$(cd "$state_root" && pwd -P)"

          # The workspace is bind-mounted and SELinux-relabelled (:Z).
          # Refuse anything that isn't a single project dir: a parent would
          # mount and relabel every project, and $HOME or the state root
          # would hand the agent other agents' credentials.
          case "$ws" in
            / | "$home" | "$home/Projects" | "$real_state_root" | "$real_state_root"/*)
              echo "${name}: refusing to use $ws as the workspace; cd into a project first" >&2
              exit 1
              ;;
          esac

          args=(
            --userns=keep-id
            --shm-size=1gb
            --cap-drop=ALL
            --security-opt=no-new-privileges
            -e AGENT=${agent}
            -v "$ws:/workspace:Z"
          )
          ${lib.optionalString hostNetwork "args+=(--network=host)"}
          ${lib.concatStrings (lib.mapAttrsToList (k: v: ''
              args+=(-e ${lib.escapeShellArg "${k}=${v}"})
            '')
            env)}
          ${lib.concatMapStrings (m: ''
              mkdir -p "$state/${m.sub}"
              args+=(-v "$state/${m.sub}:${m.dest}:Z")
            '')
            mounts}

          exec podman run -it --rm "''${args[@]}" agents-sandbox "$@"
        '';
      };
  in {
    home.packages = [
      # opencode scatters state across five XDG dirs — each persisted.
      (mkLauncher {
        name = "oc";
        agent = "opencode";
        mounts = [
          {sub = "config"; dest = "/home/node/.config/opencode";}
          {sub = "data"; dest = "/home/node/.local/share/opencode";}
          {sub = "state"; dest = "/home/node/.local/state/opencode";}
          {sub = "opentui"; dest = "/home/node/.local/share/opentui";}
          {sub = "cache"; dest = "/home/node/.cache/opencode";}
        ];
      })

      # omp / pi / claude: one primary dotfile dir each, as a starting
      # point. Once you confirm where else they write (config, cache,
      # auth), split them out like opencode so nothing resets per run.
      (mkLauncher {
        name = "omp";
        agent = "omp";
        mounts = [{sub = ""; dest = "/home/node/.omp";}];
      })

      (mkLauncher {
        name = "pi";
        agent = "pi";
        mounts = [{sub = ""; dest = "/home/node/.pi";}];
      })

      # No --network=host: claude talks only to Anthropic's API, not the
      # 127.0.0.1-bound local model server.
      (mkLauncher {
        name = "claude";
        agent = "claude";
        hostNetwork = false;
        env.CLAUDE_CONFIG_DIR = "/home/node/.claude";
        mounts = [{sub = ""; dest = "/home/node/.claude";}];
      })
    ];
  };
}
