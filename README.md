
### `flake-compat-ci`

This is a stop-gap solution for flakes CI with stable Nix 2.3 and stable Hercules CI.

It provides the `lib.recurseIntoFlake` function, which tells nix-build and Hercules CI
which attributes to traverse for a given flake.

### Installation

Add the custom `ciNix` attribute to your flake:

Add to `flake.nix`:
```nix
{
  inputs = {
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-compat-ci.url = "github:hercules-ci/flake-compat-ci";
  };
  outputs = { 
    self,
    # ...
    flake-compat-ci,
    ...
  }:
  {
    ciNix = flake-compat-ci.lib.recurseIntoFlake self;
  };
}
```

Run `nix flake update` and add these two boilerplate files:

`flake-compat.nix`
```nix
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  inherit (lock.nodes.flake-compat.locked) owner repo rev narHash;
  flake-compat = builtins.fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
in
import flake-compat { src = ./.; }
```

`ci.nix`
```nix
(import ./flake-compat.nix).defaultNix.ciNix
```
