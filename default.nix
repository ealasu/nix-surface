{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "nixos-up";
  buildInputs = with pkgs; [ bash git ];
  shellHook = "exec bash ${./install.sh}";
}
