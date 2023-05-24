#!/usr/bin/env bash

cd /etc/nixos
rm flake.lock
nix flake lock
git add .
git commit -a -m 'updates'
#git push

#export NIX_SSHOPTS='-tt'
#nixos-rebuild switch --build-host e@nixos.lan --use-remote-sudo --verbose
#nixos-rebuild switch --build-host builder@nixos.lan --verbose
#nixos-rebuild switch --builders "ssh-ng://builder@nixos.lan" --verbose
nixos-rebuild switch --verbose
