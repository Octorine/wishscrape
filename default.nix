let pkgs = import <nixpkgs> {};
in pkgs.haskellPackages.developPackage {
    root = ./.;
    modifier = (self: pkgs.haskell.lib.addBuildDepends
                        self
                        [pkgs.cabal-install]);
}
