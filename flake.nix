{
  inputs = {
    ## ensure a successful installation by pinning nixpkgs to a known
    ## good revision
    #inputs.nixpkgs.url =
    #  "github:nixos/nixpkgs/c8f6370f7daf435d51d137dcbd80c7ebad1f21f2";
    ## after reboot, you can track latest stable by using
    #inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    ## or track rolling release by using
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs.config.allowUnfreePredicate = (pkg: true);
    nixos-hardware.url = "github:ealasu/nixos-hardware/feature/surface-linux-6.3.3";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, lanzaboote }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = #nixpkgs.legacyPackages.${system};
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in {
      nixosConfigurations = {
        nixpad = lib.nixosSystem {
          inherit system;
          modules = [
            # TODO: comment to disable custom kernel
            nixos-hardware.nixosModules.microsoft-surface-pro-intel

            lanzaboote.nixosModules.lanzaboote
            (import ./configuration.nix {
              inherit inputs pkgs nixpkgs lib;
            })
          ];
        };
      };
    };
}
