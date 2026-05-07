{
  # Nix flake for AMBER MD Tutorial 0 (alanine dipeptide).
  #
  # Strategy: hybrid Nix + conda-forge.
  #   - Nix provides `micromamba` (a small conda implementation) and a few
  #     shell helpers.
  #   - micromamba then installs `ambertools` and `grace` from conda-forge
  #     into a project-local environment at ./.mamba-env/.
  #   - Everything stays under this repo. No global pollution.
  #
  # Why hybrid: AmberTools is not packaged in nixpkgs, but it IS on
  # conda-forge (with osx-arm64 + linux-64 support). Going through
  # micromamba is the cleanest path.
  #
  # Usage (from the repo root):
  #   nix develop          # first run: 5-15 min to download & install
  #                        # subsequent runs: a few seconds
  #   sander -h            # verify AmberTools is in PATH
  description = "AMBER MD Tutorial 0 — alanine dipeptide simulation hands-on";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "amber-tutorial0";

          # Tools that come from Nix itself (= always available the moment
          # `nix develop` returns). The conda env, set up below, layers on
          # top of these for AmberTools-specific tools.
          packages = with pkgs; [
            micromamba   # tiny conda → installs ambertools/grace/perl
            bashInteractive
            curl
            gnumake
            coreutils
          ];

          shellHook = ''
            # -----------------------------------------------------------
            # Bootstrap a project-local conda env on first entry.
            # -----------------------------------------------------------

            # All conda state lives inside this repo so cloning gives a
            # reproducible setup (and uninstall = `rm -rf .mamba-*`).
            export MAMBA_ROOT_PREFIX="$PWD/.mamba-root"
            ENV_PATH="$PWD/.mamba-env"

            # Pull micromamba's shell integration into this bash session.
            # After this, `micromamba activate` works.
            eval "$(micromamba shell hook --shell=bash)"

            # Create the env from environment.yml if it doesn't yet exist.
            if [ ! -d "$ENV_PATH" ]; then
              echo ""
              echo "================================================================"
              echo " First run detected — creating conda environment at:"
              echo "   $ENV_PATH"
              echo ""
              echo " This downloads AmberTools (~3 GB) from conda-forge and may"
              echo " take 5-15 minutes depending on your network. After this,"
              echo " future \`nix develop\` invocations will be near-instant."
              echo "================================================================"
              echo ""
              micromamba create -y -p "$ENV_PATH" -f environment.yml \
                || { echo "ERROR: environment creation failed."; \
                     echo "Inspect output above, then try: rm -rf .mamba-env .mamba-root && nix develop"; \
                     return 1; }
            fi

            # Activate the env: prepends $ENV_PATH/bin to PATH so that
            # sander, tleap, cpptraj, gnuplot, etc. become available.
            micromamba activate "$ENV_PATH"

            echo ""
            echo "=========================================="
            echo " AMBER Tutorial 0 — dev shell ready"
            echo "=========================================="
            echo "  sander  : $(command -v sander 2>/dev/null || echo 'NOT FOUND')"
            echo "  pmemd   : $(command -v pmemd 2>/dev/null || echo 'NOT FOUND')"
            echo "  tleap   : $(command -v tleap 2>/dev/null || echo 'NOT FOUND')"
            echo "  cpptraj : $(command -v cpptraj 2>/dev/null || echo 'NOT FOUND')"
            echo "  gnuplot : $(command -v gnuplot 2>/dev/null || echo 'NOT FOUND')"
            echo ""
            echo "Next: cd workspace/ and follow workspace/README.md"
            echo "      Reference answers live in solutions/"
            echo ""
          '';
        };
      });
}
