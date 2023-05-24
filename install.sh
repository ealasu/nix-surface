#!/usr/bin/env bash
set -e
set -o xtrace

DISK=/dev/nvme0n1
SWAP=12G

#printf "label: gpt\n,550M,U\n,,L\n,8G,S\n" | sfdisk /dev/sdX
#printf "label: gpt\n,550M,U\n,,L\n" | sfdisk $DISK

# Create the partitions
printf "size=1G, type=U, name=BOOT\n size=+, type=L, name=nixos\n" | sfdisk $DISK

# Format the EFI partition
mkfs.vfat -n BOOT "$DISK"p1

cryptsetup --verify-passphrase -v luksFormat "$DISK"p2
cryptsetup open "$DISK"p2 enc

# Creat the swap inside the encrypted partition
pvcreate /dev/mapper/enc
vgcreate lvm /dev/mapper/enc

lvcreate --size $SWAP --name swap lvm
lvcreate --extents 100%FREE --name root lvm

mkswap /dev/lvm/swap
mkfs.btrfs /dev/lvm/root

swapon /dev/lvm/swap

# Then create subvolumes

mount -t btrfs /dev/lvm/root /mnt

# We first create the subvolumes outlined above:
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/nix
btrfs subvolume create /mnt/persist
btrfs subvolume create /mnt/log

# We then take an empty *readonly* snapshot of the root subvolume,
# which we'll eventually rollback to on every boot.
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

umount /mnt


# Mount the directories

mount -o subvol=root,compress=zstd,noatime /dev/lvm/root /mnt

mkdir /mnt/home
mount -o subvol=home,compress=zstd,noatime /dev/lvm/root /mnt/home

mkdir /mnt/nix
mount -o subvol=nix,compress=zstd,noatime /dev/lvm/root /mnt/nix

mkdir /mnt/persist
mount -o subvol=persist,compress=zstd,noatime /dev/lvm/root /mnt/persist

mkdir -p /mnt/var/log
mount -o subvol=log,compress=zstd,noatime /dev/lvm/root /mnt/var/log

# don't forget this!
mkdir /mnt/boot
mount "$DISK"p1 /mnt/boot

nixos-generate-config --root /mnt

cd /mnt/etc/nixos
rm configuration.nix
mv hardware-configuration.nix /tmp/
git clone https://github.com/ealasu/nix-surface .
mv /tmp/hardware-configuration.nix ./
git add .
git config --global user.email e
git config --global user.name e
git commit -a -m 'add hardware-configuration.nix'

nix-env -f '<nixpkgs>' -iA git
nix-env -f '<nixpkgs>' -iA sbctl

sbctl create-keys
mv /etc/secureboot /mnt/etc/secureboot

nixos-install --root /mnt --flake "git+file:///mnt/etc/nixos#nixpad"

reboot

