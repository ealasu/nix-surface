{ config, lib, pkgs, ... }:

let
  cfg = config.zfs-root.boot;
  inherit (lib) mkIf types mkDefault mkOption mkMerge strings;
  inherit (builtins) head toString map tail;
in {
  options.zfs-root.boot = {
    enable = mkOption {
      description = "Enable root on ZFS support";
      type = types.bool;
      default = true;
    };
    devNodes = mkOption {
      description = "Specify where to discover ZFS pools";
      type = types.str;
      apply = x:
        assert (strings.hasSuffix "/" x
          || abort "devNodes '${x}' must have trailing slash!");
        x;
      default = "/dev/disk/by-id/";
    };
    bootDevices = mkOption {
      description = "Specify boot devices";
      type = types.nonEmptyListOf types.str;
    };
    availableKernelModules = mkOption {
      type = types.nonEmptyListOf types.str;
      default = [ "uas" "nvme" "ahci" ];
    };
    kernelParams = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    immutable = mkOption {
      description = "Enable root on ZFS immutable root support";
      type = types.bool;
      default = false;
    };
    removableEfi = mkOption {
      description = "install bootloader to fallback location";
      type = types.bool;
      default = true;
    };
    partitionScheme = mkOption {
      default = {
        biosBoot = "-part5";
        efiBoot = "-part1";
        swap = "-part4";
        bootPool = "-part2";
        rootPool = "-part3";
      };
      description = "Describe on disk partitions";
      type = types.attrsOf types.str;
    };
    sshUnlock = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };
  config = mkIf (cfg.enable) (mkMerge [
    #{
      #zfs-root.fileSystems.datasets = {
        #"rpool/nixos/home" = mkDefault "/home";
        #"rpool/nixos/var/lib" = mkDefault "/var/lib";
        #"rpool/nixos/var/log" = mkDefault "/var/log";
        #"bpool/nixos/root" = "/boot";
      #};
    #}
    #(mkIf (!cfg.immutable) {
      #zfs-root.fileSystems.datasets = { "rpool/nixos/root" = "/"; };
    #})
    #(mkIf cfg.immutable {
      #zfs-root.fileSystems = {
        #datasets = {
          #"rpool/nixos/empty" = "/";
          #"rpool/nixos/root" = "/oldroot";
        #};
        #bindmounts = {
          #"/oldroot/nix" = "/nix";
          #"/oldroot/etc/nixos" = "/etc/nixos";
        #};
      #};
      #boot.initrd.postDeviceCommands = ''
        #if ! grep -q zfs_no_rollback /proc/cmdline; then
          #zpool import -N rpool
          #zfs rollback -r rpool/nixos/empty@start
          #zpool export -a
        #fi
      #'';
    #})
    {
      #zfs-root.fileSystems = {
        #efiSystemPartitions =
          #(map (diskName: diskName + cfg.partitionScheme.efiBoot)
            #cfg.bootDevices);
        #swapPartitions =
          #(map (diskName: diskName + cfg.partitionScheme.swap) cfg.bootDevices);
      #};

      boot = {
        #kernelPackages = pkgs.linuxPackages_latest;
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
        supportedFilesystems = [ "btrfs" ];
        loader = {
          # systemd-boot = {
          #   enable = true;
          #   configurationLimit = 10;
          # };
          efi.canTouchEfiVariables = true;
          grub = {
            enable = true;
            version = 2;
            device = "nodev";
            efiSupport = true;
            enableCryptodisk = true;
            configurationLimit = 40;
          };
        };
        initrd = {
          availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc" ];
          kernelModules = [ "dm-snapshot" ];
          luks.devices = {
            root = {
              #device = "/dev/disk/by-uuid/14fd8688-c7f6-4831-b82d-90a02acf4f12";
              #device = "/dev/disk/by-id/nvme-HFM256GD3GX013N-SKhynix_CYB6N00231640676G";
              device = "/dev/disk/by-partlabel/nixos";
              preLVM = true;
            };
          };
        };
      };


      #boot = {
        #kernelPackages =
          #mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages;
        #initrd.availableKernelModules = cfg.availableKernelModules;
        #kernelParams = cfg.kernelParams;
        #supportedFilesystems = [ "zfs" "btrfs" ];
        #zfs = {
          #devNodes = cfg.devNodes;
          #forceImportRoot = mkDefault false;
        #};
        #loader = {
          #efi = {
            #canTouchEfiVariables = (if cfg.removableEfi then false else true);
            #efiSysMountPoint = ("/boot/efis/" + (head cfg.bootDevices)
              #+ cfg.partitionScheme.efiBoot);
          #};
          #generationsDir.copyKernels = true;
          #grub = {
            #enable = true;
            #devices = (map (diskName: cfg.devNodes + diskName) cfg.bootDevices);
            #efiInstallAsRemovable = cfg.removableEfi;
            #copyKernels = true;
            #efiSupport = true;
            #zfsSupport = true;
            #extraInstallCommands = (toString (map (diskName: ''
              #set -x
              #${pkgs.coreutils-full}/bin/cp -r ${config.boot.loader.efi.efiSysMountPoint}/EFI /boot/efis/${diskName}${cfg.partitionScheme.efiBoot}
              #set +x
            #'') (tail cfg.bootDevices)));
          #};
        #};
      #};
    }
    (mkIf cfg.sshUnlock.enable {
      boot.initrd = {
        network = {
          enable = true;
          ssh = {
            enable = true;
            hostKeys = [
              "/var/lib/ssh_unlock_zfs_ed25519_key"
              "/var/lib/ssh_unlock_zfs_rsa_key"
            ];
            authorizedKeys = cfg.sshUnlock.authorizedKeys;
          };
          postCommands = ''
            tee -a /root/.profile >/dev/null <<EOF
            if zfs load-key rpool/nixos; then
               pkill zfs
            fi
            exit
            EOF'';
        };
      };
    })
  ]);
}
