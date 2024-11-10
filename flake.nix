{
  description = "Mail Sender microservice";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustVersion = pkgs.rust-bin.stable.latest.default;
        ame-mail-sender = pkgs.rustPlatform.buildRustPackage {
          pname = "ame-mail-sender";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          buildInputs = with pkgs; [ pkg-config ];
        };
        ame-mail-sender-service = import ./service.nix;
      in
      {
        packages.default = ame-mail-sender;
        packages.ame-mail-sender = ame-mail-sender;
        nixosModules.ame-mail-sender = ame-mail-sender-service;
      }
    );
}
