{ config, lib, pkgs, ... }:
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
        ExecStart = "${pkgs.ame-mail-sender}/bin/ame-mail-sender --config /run/ame-mail-sender/config.toml";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
