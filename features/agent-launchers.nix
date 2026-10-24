{...}: {
  flake.homeModules.agent-launchers = {
    pkgs,
    lib,
    ...
  }: let
    # Launchers for the shared agents-sandbox image (built by `bsbx` in
    # ~/Projects/tdev). Installed from the read-only Nix store on purpose:
    # an agent whose workspace is tdev can edit anything in it, so nothing
    # the host executes may live there.
    #
    # podman deliberately NOT in runtimeInputs — use the host's rootless
    # podman (its storage, registries and SELinux policy), not a Nix one.
    # Per-agent state under $XDG_STATE_HOME/agents/<agent>/<sub>, mounted at
    # <dest> in the container. One table, used by both the one-shot
    # launchers and `sbx`.
    agents = {
      # opencode scatters state across five XDG dirs — each persisted.
      opencode = {
        launcher = "oc";
        mounts = [
          {
            sub = "config";
            dest = "/home/node/.config/opencode";
          }
          {
            sub = "data";
            dest = "/home/node/.local/share/opencode";
          }
          {
            sub = "state";
            dest = "/home/node/.local/state/opencode";
          }
          {
            sub = "opentui";
            dest = "/home/node/.local/share/opentui";
          }
          {
            sub = "cache";
            dest = "/home/node/.cache/opencode";
          }
        ];
      };
      # omp / pi / claude: one primary dotfile dir each, as a starting
      # point. Once you confirm where else they write (config, cache,
      # auth), split them out like opencode so nothing resets per run.
      omp = {
        launcher = "omp";
        mounts = [
          {
            sub = "";
            dest = "/home/node/.omp";
          }
        ];
      };
      pi = {
        launcher = "pi";
        mounts = [
          {
            sub = "";
            dest = "/home/node/.pi";
          }
        ];
      };
      claude = {
        launcher = "claude";
        # No --network=host: claude talks only to Anthropic's API, not the
        # 127.0.0.1-bound local model server.
        hostNetwork = false;
        env.CLAUDE_CONFIG_DIR = "/home/node/.claude";
        mounts = [
          {
            sub = "";
            dest = "/home/node/.claude";
          }
        ];
      };
    };

    # Shared preamble: resolve physical paths and refuse a workspace that
    # isn't a single project dir. On Fedora Atomic /home -> /var/home, so
    # a $PWD reached via /home/tom/... would never match $HOME otherwise.
    # A parent dir would mount (and SELinux-relabel) every project; $HOME
    # or the state root would hand agents other agents' credentials.
    # tdev is refused too: it holds containers/ (what bsbx builds) and a
    # devenv.nix whose enterShell runs on the host on `cd` — an agent
    # with write access there could get code executed outside the sandbox.
    preamble = name: ''
      state_root="''${XDG_STATE_HOME:-$HOME/.local/state}"
      mkdir -p "$state_root/agents"
      ws="$(pwd -P)"
      home="$(cd "$HOME" && pwd -P)"
      real_state_root="$(cd "$state_root" && pwd -P)"
      case "$ws" in
        / | "$home" | "$home/Projects" | "$home/Projects/tdev" | "$home/Projects/tdev"/* | "$real_state_root" | "$real_state_root"/*)
          echo "${name}: refusing to use $ws as the workspace; cd into a project first" >&2
          exit 1
          ;;
      esac

      args=(
        --userns=keep-id
        --shm-size=1gb
        --cap-drop=ALL
        --security-opt=no-new-privileges
        # Fixed MCS level shared by all agent containers: :Z then labels
        # mounts for "agent sandboxes" as a group, so several can share a
        # workspace or state dir concurrently, while other containers
        # (kind, llama-server, …) still can't touch them. Default per-
        # container random levels make a second :Z mount relabel files
        # away from the first container mid-session.
        #
        # Comma pairs the MCS categories — quoted so shellcheck (SC2054)
        # doesn't mistake it for an array separator.
        --security-opt=label=level:"s0:c731,c732"
        -v "$ws:/workspace:Z"
      )
    '';

    agentArgs = agent: def:
      lib.concatStrings (lib.mapAttrsToList (k: v: ''
        args+=(-e ${lib.escapeShellArg "${k}=${v}"})
      '') (def.env or {}))
      + lib.concatMapStrings (m: ''
        mkdir -p "$state_root/agents/${agent}/${m.sub}"
        args+=(-v "$state_root/agents/${agent}/${m.sub}:${m.dest}:Z")
      '')
      def.mounts;

    # podman's default detach keys are ctrl-p,ctrl-q, which swallow ctrl+p
    # (opencode's command palette, readline's previous-history). Disable.
    noDetach = "--detach-keys=";

    mkLauncher = agent: def:
      pkgs.writeShellApplication {
        name = def.launcher;
        text = ''
          ${preamble def.launcher}
          args+=(-e AGENT=${agent})
          ${lib.optionalString (def.hostNetwork or true) "args+=(--network=host)"}
          ${agentArgs agent def}
          exec podman run -it --rm ${noDetach} "''${args[@]}" agents-sandbox "$@"
        '';
      };

    # sbx: a long-lived shell container for the current project, with every
    # agent's state mounted so any of them can be run from inside it.
    # Started if missing/stopped, then entered with bash; exiting the shell
    # leaves it running for the next `sbx`.
    #
    # Trade-off vs the one-shot launchers: all agents' credentials share one
    # container, so an agent running in it can read the others' auth.
    sbx = pkgs.writeShellApplication {
      name = "sbx";
      text = ''
        usage() {
          echo "usage: sbx [--recreate | --stop | --rm | --list]" >&2
          echo "  (no args)   start this project's sandbox if needed, open bash in it" >&2
          echo "  --recreate  remove and recreate it (e.g. after a bsbx rebuild)" >&2
          echo "  --stop      stop it;  --rm  remove it;  --list  show all sbx containers" >&2
          exit 2
        }

        if [[ "''${1:-}" == --list ]]; then
          exec podman ps -a --filter label=tdev.sbx.workspace \
            --format '{{.Names}}\t{{.Status}}\t{{index .Labels "tdev.sbx.workspace"}}'
        fi

        ${preamble "sbx"}

        # One container per workspace path: readable basename + path hash,
        # so two projects with the same dir name never share a container.
        base="$(basename "$ws")"
        base="''${base//[^A-Za-z0-9_.-]/-}"
        name="sbx-''${base}-$(printf '%s' "$ws" | sha256sum | cut -c1-8)"
        img=agents-sandbox

        case "''${1:-}" in
          "") ;;
          --stop) exec podman stop -t 5 "$name" ;;
          --rm) exec podman rm -f "$name" ;;
          --recreate) podman rm -f "$name" >/dev/null 2>&1 || true ;;
          *) usage ;;
        esac

        if podman container exists "$name"; then
          if [[ "$(podman container inspect -f '{{.Image}}' "$name")" != \
                "$(podman image inspect -f '{{.Id}}' "$img")" ]]; then
            echo "sbx: $name runs an older $img image — 'sbx --recreate' to pick up the rebuild" >&2
          fi
          if [[ "$(podman container inspect -f '{{.State.Running}}' "$name")" != true ]]; then
            podman start "$name" >/dev/null
          fi
        else
          # Host network so omp/pi/opencode reach the 127.0.0.1 model server
          # (claude doesn't need it, but one container means one choice).
          args+=(--network=host --init --label "tdev.sbx.workspace=$ws")
          ${lib.concatStrings (lib.mapAttrsToList agentArgs agents)}
          # Keep-alive instead of the image entrypoint: the entrypoint
          # launches a single agent (AGENT=…); here you pick from the shell.
          podman run -d --name "$name" "''${args[@]}" \
            --entrypoint sleep "$img" infinity >/dev/null
          echo "sbx: started $name" >&2
        fi

        exec podman exec -it ${noDetach} -w /workspace "$name" bash
      '';
    };
  in {
    home.packages = lib.mapAttrsToList mkLauncher agents ++ [sbx];
  };
}
