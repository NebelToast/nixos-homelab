{ config, ... }:

let
  dockerBin = "${config.virtualisation.docker.package}/bin/docker";
  # Set this to your real public hostname, e.g. https://planka.example.com
  plankaBaseUrl = "sillyned.de";
in
{
  sops.secrets = {
    "planka-secret-key" = { };
    "planka-postgres-password" = { };
  };

  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

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
      volumes = [
        "planka-db-data:/var/lib/postgresql/data"
        "${config.sops.secrets."planka-postgres-password".path}:/run/secrets/postgres_password:ro"
      ];
      environment = {
        POSTGRES_DB = "planka";
        POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_password";
      };
    };

    planka = {
      image = "ghcr.io/plankanban/planka:latest";
      autoStart = true;
      dependsOn = [ "planka-postgres" ];
      ports = [ "3000:1337" ];
      extraOptions = [ "--network=planka" ];
      volumes = [
        "planka-data:/app/data"
        "${config.sops.secrets."planka-secret-key".path}:/run/secrets/secret_key:ro"
        "${config.sops.secrets."planka-postgres-password".path}:/run/secrets/database_password:ro"
      ];
      environment = {
        BASE_URL = plankaBaseUrl;
        DATABASE_URL = "postgresql://postgres:\${DATABASE_PASSWORD}@planka-postgres/planka";
        DATABASE_PASSWORD__FILE = "/run/secrets/database_password";
        SECRET_KEY__FILE = "/run/secrets/secret_key";
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
