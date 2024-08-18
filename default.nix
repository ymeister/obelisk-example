let nix-thunk = import ./deps/nix-thunk {};
    deps = with nix-thunk; mapSubdirectories thunkSource ./deps;

    haskellNix = import deps."haskell.nix" {};

    # Import nixpkgs and pass the haskell.nix provided nixpkgsArgs
    pkgs = import
      # haskell.nix provides access to the nixpkgs pins which are used by our CI,
      # hence you will be more likely to get cache hits when using these.
      # But you can also just use your own, e.g. '<nixpkgs>'.
      haskellNix.sources.nixpkgs-unstable
      # These arguments passed to nixpkgs, include some patches and also
      # the haskell.nix functionality itself as an overlay.
      haskellNix.nixpkgsArgs;

    source-repository-packages = packages:
      builtins.zipAttrsWith
        (k: vs:
          if k == "cabalProjectLocal" then pkgs.lib.strings.concatStringsSep "\n" vs
          else builtins.zipAttrsWith (_: pkgs.lib.lists.last) vs
        )
        (pkgs.lib.lists.forEach packages (p:
          let pkg = if builtins.isAttrs p then p.pkg else p;
              cond = if builtins.isAttrs p then p.cond else null;
              input = builtins.unsafeDiscardStringContext pkg;
          in {
            inputMap."${input}" = { name = builtins.baseNameOf pkg; outPath = pkg; rev = "HEAD"; };
            cabalProjectLocal = if builtins.isNull cond
            then ''
              source-repository-package
                type: git
                location: ${input}
                tag: HEAD
            ''
            else ''
              if ${cond}
                source-repository-package
                  type: git
                  location: ${input}
                  tag: HEAD
            '';
          }
        ));

    import-cabal-project = dir: file:
      let path = dir + "/${file}";
          content = ''
            -- ${path}
            ${if pkgs.lib.strings.hasPrefix "http://" file || pkgs.lib.strings.hasPrefix "https://" file
              then builtins.fetchurl file
              else builtins.readFile path
            }
          '';
          lines = pkgs.lib.strings.splitString "\n" content;
      in pkgs.lib.strings.concatStringsSep "\n" (
          pkgs.lib.lists.forEach lines (line:
            let splitLine = pkgs.lib.strings.splitString "import: " line;
                prefix = builtins.elemAt splitLine 0;
                subproject = builtins.elemAt splitLine 1;
            in if builtins.length splitLine == 2
              then pkgs.lib.strings.concatStringsSep "import: " [ prefix (import-cabal-project dir subproject) ]
              else line
          )
      );

    haskellDeps = source-repository-packages [
      (deps.obelisk + "/lib/executable-config/inject")
      (deps.obelisk + "/lib/executable-config/lookup")
      (deps.obelisk + "/lib/frontend")
      (deps.obelisk + "/lib/route")
      (deps.obelisk + "/lib/tabulation")
      { pkg = deps.obelisk + "/lib/asset/manifest"; cond = "!arch(javascript)"; }
      { pkg = deps.obelisk + "/lib/asset/serve-snap"; cond = "!arch(javascript)"; }
      { pkg = deps.obelisk + "/lib/backend"; cond = "!arch(javascript)"; }
      { pkg = deps.obelisk + "/lib/command"; cond = "!arch(javascript)"; }
      { pkg = deps.obelisk + "/lib/run"; cond = "!arch(javascript)"; }
      { pkg = deps.obelisk + "/lib/selftest"; cond = "!arch(javascript)"; }
      { pkg = deps.obelisk + "/lib/snap-extras"; cond = "!arch(javascript)"; }
      { pkg = deps.reflex-fsnotify; cond = "!arch(javascript)"; }

      (deps.reflex-dom + "/reflex-dom")
      (deps.reflex-dom + "/reflex-dom-core")
      deps.reflex
      deps.patch
    ];

    project = pkgs: pkgs.haskell-nix.project {
      src = ./.;

      inherit (haskellDeps) inputMap;
      cabalProject = import-cabal-project ./. "cabal.project";
      cabalProjectLocal = ''
        ${import-cabal-project (deps.obelisk + "/lib") "cabal.dependencies.project"}
        ${import-cabal-project deps.reflex-dom "cabal.dependencies.project"}
        ${import-cabal-project deps.reflex-fsnotify "cabal.dependencies.project"}

        ${haskellDeps.cabalProjectLocal}

        if arch(javascript)
          extra-packages: ghci
      '';

      shell.withHaddock = if pkgs.stdenv.hostPlatform.isGhcjs then false else true;

      modules = [({ pkgs, lib, ... }: {
        packages = {
          obelisk-command.components.library.build-tools = with pkgs; [ ghcid jre openssh ];
          cli-git.components.library.build-tools = with pkgs; [ git ];
          cli-nix.components.library.build-tools = with pkgs; [ nix nix-prefetch-git ];

          reflex-dom-core.components.tests = {
            gc.buildable = lib.mkForce false;
            hydration.buildable = lib.mkForce false;
            #gc.build-tools = [ pkgs.chromium ];
            #hydration.build-tools = [ pkgs.chromium ];
          };
        };
      })];

      compiler-nix-name = "ghc910";
    };

in {
  ghc = project pkgs;
  ghc-js = project pkgs.pkgsCross.ghcjs;
}
