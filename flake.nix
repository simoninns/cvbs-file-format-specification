{
  description = "CVBS File Format Specification — documentation site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs.python3Packages; [
            mkdocs
            mkdocs-material
            mkdocs-awesome-nav
          ];
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
