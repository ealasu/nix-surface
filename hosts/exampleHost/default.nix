# #
##
##  per-host configuration for exampleHost
##
##

{ system, pkgs, ... }: {
  inherit pkgs system;
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [  "nvme-HFM256GD3GX013N-SKhynix_CYB6N00231640676G" ];
      immutable = false;
      availableKernelModules = [  "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      removableEfi = true;
      kernelParams = [ ];
      sshUnlock = {
        # read sshUnlock.txt file.
        enable = false;
        authorizedKeys = [ ];
      };
    };
    networking = {
      # read changeHostName.txt file.
      hostName = "exampleHost";
      timeZone = "America/Phoenix";
      hostId = "6bc25b24";
    };
  };

  # To add more options to per-host configuration, you can create a
  # custom configuration module, then add it here.
  #my-config = {
    ## Enable custom gnome desktop on exampleHost
    #template.desktop.gnome.enable = false;
  #};
}
