{
  description = "Knight of Faith Site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        haskellPackages = pkgs.haskellPackages.override {
          overrides = final: prev:
            {
              # Add any Haskell package overrides here if needed
            };
        };

        # Site executable
        site = haskellPackages.callCabal2nix "knightoffaith" ./. { };

        # Development shell dependencies
        buildInputs = with pkgs; [
          haskellPackages.ghc
          haskellPackages.cabal-install
          haskellPackages.hakyll
          haskellPackages.haskell-language-server
          typst
          tailwindcss
          pandoc
        ];

        # Site builder script
        buildSite = pkgs.writeShellScriptBin "build-site" ''
          echo "Building site..."
          cabal run site build
          echo "Site built successfully!"
        '';

        # Development server script
        serveSite = pkgs.writeShellScriptBin "serve-site" ''
          echo "Starting development server..."
          cabal run site watch
        '';

      in {
        packages = {
          default = site;
          build = buildSite;
          serve = serveSite;
        };

        devShells.default = pkgs.mkShell {
          inherit buildInputs;
          shellHook = ''
            echo "Hakyll development environment"
            echo "Commands:"
            echo "  build-site  - Build the static site"
            echo "  serve-site  - Start development server"
            echo "  cabal run site build    - Build site"
            echo "  cabal run site watch    - Watch and rebuild"
            echo "  cabal run site clean    - Clean build"
          '';
        };
      });
}
