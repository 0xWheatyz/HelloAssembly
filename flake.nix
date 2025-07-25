{
  description = "Custom development environment for assembly!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.nasm
        pkgs.gdb
        pkgs.man-pages
        pkgs.man-pages-posix
      ];

      shellHook = ''
        if [ "$SHELL" != "$(which zsh)" ]; then
          exec zsh
        fi
        echo "Welcome to your assembly"
        export MY_VAR=dev
      '';
    };
  };
}

