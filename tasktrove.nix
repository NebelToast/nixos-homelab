{ config, ... }:

let
  tasktrovePort = 3001;
in

{
  sops.secrets."tasktrove-auth-secret".restartUnits = [ "docker-tasktrove.service" ];

  sops.templates."tasktrove.env" = {
    restartUnits = [ "docker-tasktrove.service" ];
    content = ''
      AUTH_SECRET=${config.sops.placeholder."tasktrove-auth-secret"}
    '';
  };

  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  virtualisation.oci-containers.containers.tasktrove = {
    image = "ghcr.io/dohsimpson/tasktrove:latest";
    autoStart = true;
    ports = [ "0.0.0.0:${toString tasktrovePort}:3000" ];
    volumes = [
      "/var/lib/tasktrove:/app/data"
    ];

    environmentFiles = [
      config.sops.templates."tasktrove.env".path
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/tasktrove 0750 root root -"
  ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ tasktrovePort ];
}