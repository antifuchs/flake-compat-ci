{ ... }:
let
  filterAttrs = pred: set:
    builtins.listToAttrs (builtins.concatMap (name: let value = set.${name}; in if pred name value then [{ inherit name value; }] else [ ]) (builtins.attrNames set));

  recurseIntoAttrs = as: as // { recurseForDerivations = true; };
  optionalAttrs = b: if b then as: as else _: { };
  traverse_ = f: v: recurseIntoAttrs (builtins.mapAttrs (k: f) v);

  checkApp = app:
    if app.type != "app"
    then throw "Nix flake app type must be \"app\"."
    else
      recurseIntoAttrs {
        inherit (app) program;
      };
  getNixOS = sys: sys.config.system.build.toplevel // sys.config;

in
{
  recurseIntoFlake = { flake, systems ? null }:
    let
      filterSystems = defns: (filterAttrs
        (system: _v: (systems == null) || (builtins.elem system systems))
        defns);
    in
    recurseIntoAttrs { }
    // optionalAttrs (flake ? checks) {
      checks = traverse_ recurseIntoAttrs (filterSystems flake.checks);
    }
    // optionalAttrs (flake ? packages) {
      packages = traverse_ recurseIntoAttrs (filterSystems flake.packages);
    }
    // optionalAttrs (flake ? defaultPackage) {
      defaultPackage = recurseIntoAttrs (filterSystems flake.defaultPackage);
    }
    // optionalAttrs (flake ? apps) {
      apps = traverse_ (traverse_ checkApp) (filterSystems flake.apps);
    }
    // optionalAttrs (flake ? defaultApp) {
      defaultApp = traverse_ checkApp (filterSystems flake.defaultApp);
    }
    // optionalAttrs (flake ? legacyPackages) {
      legacyPackages = traverse_ recurseIntoAttrs (filterSystems flake.legacyPackages);
    }
    // optionalAttrs (flake ? nixosConfigurations) {
      nixosConfigurations = traverse_ getNixOS flake.nixosConfigurations;
    }
    // optionalAttrs (flake ? devShell) {
      devShell = traverse_ (s: s // { isShell = true; }) (filterSystems flake.devShell);
    }
  ;
}
