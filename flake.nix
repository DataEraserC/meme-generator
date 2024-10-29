{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    # Use my poetry2nix for quick fix (do not change it before upstream accept pr)
    poetry2nix = {
      url = "github:DataEraserC/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryApplication;
    in {
      packages = {
        meme-generator = with pkgs;
          mkPoetryApplication {
            projectDir = self;
            postPatch = ''
              # we have no chance to modify nix store so do it while packaging
              sed -i "s|meme_generator/memes/**/*.jpg,||g" pyproject.toml
              sed -i "s|meme_generator/memes/**/*.png,||g" pyproject.toml
              sed -i "s|meme_generator/memes/**/*.gif,||g" pyproject.toml
            '';
            meta = {
              description = "meme generator";
              longDescription = ''
                Meme Generator, used for creating a variety of funny and silly expression packs.
              '';
              homepage = "https://github.com/MeetWq/meme-generator";
              license = lib.licenses.agpl3Only;
              platforms = lib.platforms.all;
            };
          };
        default = self.packages.${system}.meme-generator;
        docker_builder = pkgs.dockerTools.buildLayeredImage {
          name = "meme-generator";
          tag = "latest";
          contents = [
            self.packages.${system}.meme-generator
          ];
        };
      };

      # Shell for app dependencies.
      #
      #     nix develop
      #
      # Use this shell for developing your app.
      devShells.default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.meme-generator];
      };

      # Shell for poetry.
      #
      #     nix develop .#poetry
      #
      # Use this shell for changes to pyproject.toml and poetry.lock.
      devShells.poetry = pkgs.mkShell {
        packages = [pkgs.poetry];
      };
    });
}
