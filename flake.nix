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

      dotkit = pkgs.stdenv.mkDerivation {
        pname = "dotkit";
        version = "0.1.0";

        src = ./src;

        buildInputs = with pkgs; [
          bash
          gum
          bashunit
        ];

        installPhase = ''
          local dotkit_path=$( ${
            pkgs.lib.makeBinPath [
              pkgs.gum
              pkgs.bashunit
            ]
          } )
          mkdir -p $out/bin $out/lib/dotkit

          cp -r $src/lib $out/lib/dotkit/
          cp -r $src/main.sh $out/lib/dotkit/

          # Create a wrapper script in $out/bin
          cat <<EOF > $out/bin/dotkit
          #!/usr/bin/env bash
          set -euo pipefail
          export PATH="$dotkit_path:$PATH"
          exec "$out/lib/dotkit/main.sh" "\$@"
          EOF
          chmod +x $out/bin/dotkit
        '';
        meta = with pkgs.lib; {
          description = "dotkit - the dotfile toolkit";
          license = licenses.mit;
          platforms = platforms.linux;
        };
      };

      dotkit_tests = pkgs.writeShellApplication {
        name = "run-tests";
        runtimeInputs = [
          dotkit
          pkgs.bashunit
          pkgs.gum
        ];
        text = ''
          cd ${./.}
          ./src/tests/run_tests.sh
        '';
      };
    in
    {
      packages."x86_64-linux".dotkit = dotkit;
      packages."x86_64-linux".tests = dotkit_tests;

      devShells."x86_64-linux".default = pkgs.mkShell {
        packages = [ dotkit ];
      };

      checks."x86_64-linux".default = dotkit_tests;
    };
}
