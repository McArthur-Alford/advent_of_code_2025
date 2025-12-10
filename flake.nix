{
  inputs = {
    crane = {
      url = "github:ipetkov/crane";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    rust-overlay.url = "github:oxalica/rust-overlay";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      crane,
      fenix,
      flake-utils,
      nixpkgs,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ (import rust-overlay) ];
        };

        rust-pkgs = fenix.packages.${system}.stable;

        rustToolchain = rust-pkgs.toolchain;
        craneLib = (crane.mkLib pkgs).overrideToolchain (rustToolchain);

        runtimeDeps = (
          with pkgs;
          [
            pkg-config
            libxkbcommon
            alsa-lib
            udev
            wayland
            vulkan-loader
            stdenv.cc.libc
            z3
          ]
          ++ (with xorg; [
            libXcursor
            libXrandr
            libXi
            libX11
          ])
        );
      in
      {
        packages.default = craneLib.buildPackage {
          src = craneLib.cleanCargoSource ./.;
        };

        devShells.default = craneLib.devShell {
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath runtimeDeps}";
          LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";

          hardeningDisable = [ "fortify" ];
          packages =
            (with pkgs; [
              (rust-pkgs.withComponents [
                "cargo"
                "clippy"
                "rust-src"
                "rustc"
                "rustfmt"
              ])
              rust-analyzer
              wgsl-analyzer
              just
              stdenv.cc.libc
            ])
            ++ runtimeDeps;
        };
      }
    );
}
