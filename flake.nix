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

      bashunit = pkgs.callPackage ./bashunit.nix { };

      dotkit = pkgs.stdenv.mkDerivation {
        pname = "dotkit";
        version = "0.1.0";

        src = ./src;

        buildInputs = [
          pkgs.bash
          pkgs.gum
          pkgs.yq-go
          pkgs.parallel-full
          bashunit
        ];

        installPhase = ''
          local dotkit_path=$( ${
            pkgs.lib.makeBinPath [
              pkgs.gum
              bashunit
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
          bashunit
          pkgs.gum
          pkgs.yq-go
          pkgs.parallel-full
        ];
        text = ''
          cd ${./.}
          bashunit
        '';
      };
    in
    {
      packages."x86_64-linux".default = dotkit;
      packages."x86_64-linux".tests = dotkit_tests;
      packages."x86_64-linux".bashunit = pkgs.callPackage ./bashunit.nix { };

      devShells."x86_64-linux".default = pkgs.mkShell {
        packages = [
          dotkit
          bashunit
          pkgs.gum
          pkgs.yq-go
          pkgs.parallel-full
        ];
      };

      checks."x86_64-linux".default = dotkit_tests;
    };
}
