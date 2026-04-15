{ config, ... }:
{

  sops.secrets."tailscale-auth-key".restartUnits = [ "tailscaled-autoconnect.service" ];

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-auth-key".path;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--reset=true" ];
    extraSetFlags = [
      "--ssh=true"
      "--advertise-exit-node=true"
    ];
  };

  systemd.services.tailscaled-set.after = [ "tailscaled-autoconnect.service" ];

}
