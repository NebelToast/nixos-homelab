{ ... }:

let
  glanceDomain = "glance.sillynerd.de";
  glancePort = 8081;
in
{
  services.glance = {
    enable = true;

    settings = {
      server = {
        host = "127.0.0.1";
        port = glancePort;
      };

      pages = [
        {
          name = "Home";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                }
                {
                  type = "monitor";
                  title = "Services";
                  cache = "1m";
                  sites = [
                    {
                      title = "Planka";
                      url = "https://planka.sillynerd.de";
                    }
                    {
                      title = "Glance";
                      url = "https://${glanceDomain}";
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.${glanceDomain}.extraConfig = ''
      reverse_proxy 127.0.0.1:${toString glancePort}
    '';
  };
}
