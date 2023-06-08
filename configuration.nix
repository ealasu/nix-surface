{ inputs, pkgs, nixpkgs, lib, ... }: {
  # load module config to top-level configuration
  #inherit zfs-root;
  nixpkgs.config.allowUnfree = true;

  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  system.configurationRevision = if (inputs.self ? rev) then
    inputs.self.rev
  else
    throw "refuse to build: git tree is dirty";

  system.stateVersion = "22.11";
  nix = {
    settings= {
      substituters = [
        "http://nixos.lan:3999"
      ];
      trusted-public-keys = [
        "nixos.lan:sCRxfuGGRfRns124rVRtu+x4uQjFhap59sLBJlvdCI4="
      ];
    };
    buildMachines = [ {
      hostName = "nixos.lan";
      sshUser = "builder";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      # if the builder supports building for multiple architectures, 
      # replace the previous line by, e.g.,
      # systems = ["x86_64-linux" "aarch64-linux"];
      maxJobs = 6;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      #mandatoryFeatures = [
        #"big-parallel"
      #];
    }] ;
    distributedBuilds = true;
    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  #nixpkgs.config.allowUnfree = true;

  # Enable NetworkManager for wireless networking,
  # You can configure networking with "nmtui" command.
  #networking.useDHCP = true;
  networking.networkmanager.enable = true;

  # TODO: comment to disable custom kernel
  microsoft-surface.kernelVersion = "6.3.3";

  boot = {
    # TODO: uncomment to disable custom kernel
    #kernelPackages = pkgs.linuxPackages_6_3;

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "btrfs" ];
    bootspec.enable = true;
    loader = {

            #boot.loader.systemd-boot.enable = lib.mkForce false;
      #systemd-boot = {
      #  enable = true;
      #  configurationLimit = 10;
      #};
      efi.canTouchEfiVariables = true;
      #grub = {
      #  enable = true;
      #  device = "nodev";
      #  efiSupport = true;
      #  enableCryptodisk = true;
      #  configurationLimit = 40;
      #};
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
	"ahci"
	"nvme"
	"usbhid"
	"usb_storage"
	"sd_mod"
	"sr_mod"
	"rtsx_pci_sdmmc"
      ];
      kernelModules = [ "dm-snapshot" ];
      luks.devices = {
        root = {
          device = "/dev/disk/by-partlabel/nixos";
          preLVM = true;
        };
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };


  time.timeZone = "America/Phoenix";
  networking = {
    firewall.enable = true;
    hostName = "nixpad";
    hostId = "6bc25b24";
  };

  users.users = {
    root = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD5DcQ/qe6kvjGqodZ/ePuqtKanDYveZ7jubWCZMqYGa82a93dqoMXYYf285Y3tF/lvJ8NznQKuCpA+NG4SI46ajKBMjzIGAhJlF0JaFeq90RN1gWNbQP7emmlaCVtNPGBOAVGqWtGBrFr8GxmN3gpMLcT25ESgqpp6js11APsU8JhiUQX1EKTBzVi06Ggc7MwldWWdsByD5VXou0JIbwDPpvzfXY/8E/CvxAHze3f5QTaunRjEtDMZiHyhxWmJxToWsWOiBoEGxXEUFVL3s66N3QSZGPKIFeMcptXxFMoC0y+6w3O84J3TagNcqy0yUuojuxUiwew2KO60f+V5ZeFnV3/cnkxw2C8vKfifBZPx2IkaHg+3ZONk9LxAe51m2Nts9w4Wpv2rQw0xgmcjL0idC7MDypDh21zuoLR4ohh8IqVXW68sLSm7O9g/m8/xeDs92u92xYJIe6B8tzbXnVrgjnf5pT4WlqlCvJdBzdg4Npk+ZqmE1YHjD+IatO0TXB0= e@nixos" ];
    };
    e = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
      ];
    };
  };

  programs.zsh.enable = true;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/scan/not-detected.nix"
    ./hardware-configuration.nix
  ];


  #boot.zfs.forceImportRoot = lib.mkDefault false;

  nix.settings.experimental-features = lib.mkDefault [ "nix-command" "flakes" ];

  programs.git.enable = true;

  security = {
    doas.enable = lib.mkDefault true;
    sudo.enable = lib.mkDefault true;
  };

  services.xserver = {
    enable = true;
    #displayManager.enable = true;
    #displayManager.gdm.wayland = true;
    #desktopManager.gnome.enable = true;

    displayManager = {
      #gdm.enable = true;
      #gdm.wayland = true;

      sddm.enable = true;
      defaultSession = "plasmawayland";

      autoLogin.enable = true;
      autoLogin.user = "e";
    };
    desktopManager = {
      #gnome.enable = true;
      plasma5.enable = true;
    };
  };
  programs.xwayland.enable = true;
  programs.dconf.enable = true;

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;


  environment = {
    systemPackages = with pkgs; [
      #firefox-bin
      brave
      #chromium
      google-chrome
      #kitty
      alacritty
      maliit-keyboard
      ripgrep
      htop
      sbctl
      tigervnc
      #libsForQt5.qtstyleplugin-kvantum
    ];

    #shellInit = ''
      #export GTK_PATH=$GTK_PATH:${pkgs.pantheon.elementary-gtk-theme}/lib/gtk-2.0
      #export GTK2_RC_FILES=$GTK2_RC_FILES:${pkgs.pantheon.elementary-gtk-theme}/share/themes/oxygen-gtk/gtk-2.0/gtkrc
    #'';

    variables = {
      # Make firefox have smooth scrolling
      #MOZ_USE_XINPUT2 = "1";
      # Make firefox use wayland
      #MOZ_ENABLE_WAYLAND = "1";
      # Make chromium use wayland
      #NIXOS_OZONE_WL = "1";

      #SSH_ASKPASS = "${pkgs.kssh}/bin/ksshaskpass";
      #SSH_ASKPASS_REQUIRE = "prefer";
    };
  };

  location = {
    latitude = 33.5;
    longitude = -111.9;
  };

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=5s
  '';

  security.pam.services.kwallet = {
    name = "kwallet";
    enableKwallet = true;
  };

  programs = {
    ssh = {
      startAgent = true;
      #askPassword = pkgs.lib.mkForce "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
      askPassword = "${pkgs.ksshaskpass.out}/bin/ksshaskpass";
    };
    mosh.enable = true;
    firejail = {
      enable = true;
      wrappedBinaries = {
        firefox = {
          executable = "${pkgs.firefox-bin}/bin/firefox";
          profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
          extraArgs = [
            # Required for U2F USB stick
            "--ignore=private-dev"
            # Enforce dark mode
            "--env=GTK_THEME=Adwaita:dark"
            # Smooth scrolling
            "--env=MOZ_USE_XINPUT2=1"
            # Use wayland
            "--env=MOZ_ENABLE_WAYLAND=1"
            # Make chromium use wayland
            "--env=NIXOS_OZONE_WL=1"
            # Enable system notifications
            "--dbus-user.talk=org.freedesktop.Notifications"
          ];
        };
        chromium = {
          executable = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland";
          profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
          extraArgs = [
            # Enforce dark mode
            "--env=GTK_THEME=Adwaita:dark"
            # Enable system notifications
            "--dbus-user.talk=org.freedesktop.Notifications"
          ];
        };
      };
    };
  };

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      fira-code
      fira-mono
      iosevka
      roboto
      lato
      source-code-pro
      font-awesome
      liberation_ttf
      powerline-fonts
      (import ./apple-fonts.nix { inherit pkgs; })
    ];
  };

  virtualisation = {
    docker = {
      enable = true;
    };
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  services = {
    fstrim.enable = true;
    openssh = {
      enable = true;
      settings = { PasswordAuthentication = lib.mkDefault false; };
    };
    flatpak.enable = true;
    auto-cpufreq.enable = true;
  };

  systemd.services.iptsd-suspend = {
    wantedBy = [ "suspend.target" ];
    after = [ "suspend.target" ];
    serviceConfig.ExecStart = "${pkgs.systemd}/bin/systemctl --no-block restart iptsd.service";
  };

}
