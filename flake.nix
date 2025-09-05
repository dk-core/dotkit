{
  description = "dotkit - the dotfile toolkit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      ...
    }@inputs:
    let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      packages."x86_64-linux".default = pkgs.stdenv.mkDerivation {
        pname = "dotkit";
        version = "0.1.0";

        src = ./src;

        buildInputs = with pkgs; [ bash ];
        propagatedBuildInputs = with pkgs; [ gum ];

        installPhase = ''
          mkdir -p $out/bin $out/libexec/dotkit
          cp -r $src/* $out/libexec/dotkit/

          # Create a wrapper script in $out/bin
          cat <<EOF > $out/bin/dotkit
          #!/usr/bin/env bash
          set -euo pipefail
          exec $out/libexec/dotkit/main.sh "\$@"
          EOF
          chmod +x $out/bin/dotkit
        '';

        meta = with pkgs.lib; {
          description = "dotkit - the dotfile toolkit";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };

      packages."x86_64-linux".tests = pkgs.writeShellApplication {
        name = "run-tests";
        runtimeInputs = with pkgs; [ bashunit ];
        text = ''
          cd ${./.}
          bash ./src/tests/run_tests.sh
        '';
      };

      devShells."x86_64-linux".default = pkgs.mkShell {
        buildInputs = with pkgs; [
          bashunit
          shellcheck
          shfmt
          jq
          yq
          fzf
          ripgrep
          gum
        ];

        # Make the built package available in the dev shell
        packages = [ (inputs.self.packages."x86_64-linux".default) ];
      };

      checks."x86_64-linux".default =
        pkgs.runCommand "flake-checks"
          {
            buildInputs = with pkgs; [ bashunit ];
            src = ./src;
          }
          ''
            # Copy the contents of the src directory
            cp -r $src/. $out

            # Change to the tests directory and run the test runner
            cd $out/tests
            chmod +x run_tests.sh
            bash ./run_tests.sh
          '';

    };
}
