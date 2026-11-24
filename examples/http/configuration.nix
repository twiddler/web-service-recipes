{
  services.nginx = {
    enable = true;
    virtualHosts.localhost = {
      locations."/" = {
        return = "200 'Hello world!'";
        extraConfig = ''
          default_type text/html;
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # HTTP (not HTTPS)
  ];

  users.mutableUsers = false;

  users.users.alice = {
    isNormalUser = true;
    description = "alice";
    extraGroups = [
      "wheel"
    ];
    password = "password";
  };

}
