{ nixpkgs ? import <nixpkgs> {}, compiler ? "default", doBenchmark ? false }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, aeson, base, bytestring, cassava, containers
      , http-client, http-conduit, lib, uri-encode, vector, cabal-install
      }:
      mkDerivation {
        pname = "wishscrape";
        version = "0.1.0.0";
        src = ./.;
        isLibrary = false;
        isExecutable = true;
        executableHaskellDepends = [
          aeson base bytestring cassava containers http-client http-conduit
          uri-encode vector cabal-install
        ];
        description = "A program to export your Steam wishlist to a csv file";
        license = lib.licenses.gpl3Plus;
        mainProgram = "wishscrape";
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  variant = if doBenchmark then pkgs.haskell.lib.doBenchmark else pkgs.lib.id;

  drv = variant (haskellPackages.callPackage f {});

in

  if pkgs.lib.inNixShell then drv.env else drv
