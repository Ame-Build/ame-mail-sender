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
      in
      {
        packages.default = ame-mail-sender;
        nixosModules.ame-mail-sender = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.ame-mail-sender;
            configFile = pkgs.writeText "ame-mail-sender.toml" ''
              log_level = "${cfg.log_level}"
              smtp_server_url = "${cfg.smtp}"
              nats = "${cfg.nats}"
            '';
          in
          {
            options.services.ame-mail-sender = {
              enable = mkEnableOption "Ame Mail Sender service";
              log_level = mkOption {
                type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
                default = "INFO";
                description = ''
                  Log level for the Ame Mail Sender service.
                '';
              };
              smtp = mkOption {
                type = types.string;
                description = ''
                  SMTP server to use for sending emails.
                '';
                example = "smtp://example.com:587";
              };
              nats = mkOption {
                type = types.string;
                description = ''
                  NATS server to use for pub/sub.
                '';
                example = "nats://example.com:4222";
              };
            };
            config = mkIf cfg.enable {
              systemd.services.ame-mail-sender = {
                description = "Ame Mail Sender Service";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];

                serviceConfig = {
                  User = "nobody";
                  ExecStartPre = "${pkgs.coreutils}/bin/cp ${configFile} /run/ame-mail-sender/config.toml";
                  ExecStart = lib.mkForce "${self.packages.${system}.default}/bin/ame-mail-sender --config /run/ame-mail-sender/config.toml";
                  Restart = "always";
                  RestartSec = "10";
                };
              };
            };
          }
        ;
      }
    );
}
