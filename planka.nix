{ config, ... }:

let
  dockerBin = "${config.virtualisation.docker.package}/bin/docker";
  # Set this to your real public hostname, e.g. https://planka.example.com
  plankaBaseUrl = "https://planka.sillynerd.de";
in
{
  sops.secrets = {
    "planka-secret-key" = { };
    "planka-postgres-password" = { };
  };

  sops.templates = {
    "planka-app.env" = {
      restartUnits = [ "docker-planka.service" ];
      content = ''
        DATABASE_URL=postgresql://postgres@planka-postgres/planka
        PGPASSWORD=${config.sops.placeholder."planka-postgres-password"}
        SECRET_KEY=${config.sops.placeholder."planka-secret-key"}
      '';
    };

    "planka-postgres.env" = {
      restartUnits = [
        "docker-planka-postgres.service"
        "docker-planka.service"
      ];
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder."planka-postgres-password"}
      '';
    };
  };

  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    virtualHosts."planka.sillynerd.de".extraConfig = ''
      reverse_proxy 127.0.0.1:3000
    '';
  };

  systemd.services.planka-prepare = {
    description = "Prepare Planka runtime and networking";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${dockerBin} network inspect planka >/dev/null 2>&1 || ${dockerBin} network create planka
    '';
  };

  virtualisation.oci-containers.containers = {
    planka-postgres = {
      image = "postgres:16-alpine";
      autoStart = true;
      extraOptions = [ "--network=planka" ];
      volumes = [ "planka-db-data:/var/lib/postgresql/data" ];
      environmentFiles = [ config.sops.templates."planka-postgres.env".path ];
      environment = {
        POSTGRES_DB = "planka";
      };
    };

    planka = {
      image = "ghcr.io/plankanban/planka:latest";
      autoStart = true;
      dependsOn = [ "planka-postgres" ];
      ports = [ "127.0.0.1:3000:1337" ];
      extraOptions = [ "--network=planka" ];
      volumes = [ "planka-data:/app/data" ];
      environmentFiles = [ config.sops.templates."planka-app.env".path ];
      environment = {
        BASE_URL = plankaBaseUrl;
      };
    };
  };

  systemd.services.docker-planka-postgres = {
    after = [ "planka-prepare.service" ];
    requires = [ "planka-prepare.service" ];
  };

  systemd.services.docker-planka = {
    after = [ "planka-prepare.service" ];
    requires = [ "planka-prepare.service" ];
  };
}
