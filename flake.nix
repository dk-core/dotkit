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

        src = ./.;

        buildInputs = with pkgs; [ bash ];
        propagatedBuildInputs = with pkgs; [ gum ];

        installPhase = ''
          mkdir -p $out/bin $out/lib/dotkit

          # Copy the entire lib directory structure
          cp -r src/lib/* $out/lib/dotkit/

          # Copy main script and make it executable
          cp src/main.sh $out/bin/dotkit
          chmod +x $out/bin/dotkit

          # Update the base directory path and remove lib/ prefix from source statements
          substituteInPlace $out/bin/dotkit \
            --replace 'SRC_DIR="$(dirname "$(realpath "$0")")"' 'SRC_DIR="$(dirname "$(realpath "$0")")/../lib/dotkit"' \
            --replace 'source "$SRC_DIR/lib/' 'source "$SRC_DIR/'
        '';

        meta = with pkgs.lib; {
          description = "dotkit - the dotfile toolkit";
          license = licenses.mit;
          platforms = platforms.linux;
        };
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
    };
}
