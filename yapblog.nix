{ ... }:

let
  # Set this to your real blog domain.
  blogDomain = "yappblog.de";
  blogRoot = "/var/lib/yapblog/site";
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/yapblog 0755 julius users -"
    "d ${blogRoot} 0755 julius users -"
  ];

  services.caddy = {
    enable = true;
    virtualHosts.${blogDomain}.extraConfig = ''
      encode zstd gzip
      root * ${blogRoot}
      file_server
    '';
  };
}
