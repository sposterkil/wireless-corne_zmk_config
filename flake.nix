{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }:
  let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);

    src = nixpkgs.lib.cleanSourceWith {
      src = self;
      filter = path: type:
        let base = builtins.baseNameOf path;
        in (nixpkgs.lib.hasSuffix ".board" base)
        || (nixpkgs.lib.hasSuffix ".cmake" base)
        || (nixpkgs.lib.hasSuffix ".conf" base)
        || (nixpkgs.lib.hasSuffix ".defconfig" base)
        || (nixpkgs.lib.hasSuffix ".dts" base)
        || (nixpkgs.lib.hasSuffix ".dtsi" base)
        || (nixpkgs.lib.hasSuffix ".json" base)
        || (nixpkgs.lib.hasSuffix ".keymap" base)
        || (nixpkgs.lib.hasSuffix ".overlay" base)
        || (nixpkgs.lib.hasSuffix ".shield" base)
        || (nixpkgs.lib.hasSuffix ".yml" base)
        || (nixpkgs.lib.hasSuffix ".yaml" base)
        || (nixpkgs.lib.hasPrefix "Kconfig" base)
        || (nixpkgs.lib.hasSuffix "_defconfig" base)
        || type == "directory";
    };

    zephyrDepsHash = "sha256-4LxcKpDKa93TOhoqvNmjxf1ZeHAFjV8hQYJaT/MjzT0=";
  in {
    packages = forAllSystems (system:
    let
      buildKeyboard = zmk-nix.legacyPackages.${system}.buildKeyboard;
      common = { inherit src zephyrDepsHash; };
    in rec {
      default = all;

      all = nixpkgs.legacyPackages.${system}.linkFarm "blecorne-all" [
        { name = "left.uf2";  path = "${firmware}/zmk.uf2"; }
        { name = "right.uf2"; path = "${right}/zmk.uf2"; }
        { name = "reset.uf2"; path = "${settings-reset}/zmk.uf2"; }
      ];

      # firmware = left (central half); used by the update script to locate zephyrDepsHash
      firmware = buildKeyboard (common // {
        name = "firmware";
        board = "blecorne_left";
        enableZmkStudio = true;
        meta = {
          description = "ZMK firmware for blecorne left (central)";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      });

      right = buildKeyboard (common // {
        name = "blecorne-right";
        board = "blecorne_right";
      });

      settings-reset = buildKeyboard (common // {
        name = "blecorne-settings-reset";
        board = "blecorne_right";
        shield = "settings_reset";
      });

      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
