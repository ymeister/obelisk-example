let projects = import ./default.nix;
    project = projects.ghc;
in project.shellFor {
  withHoogle = true;
  packages = ps: with ps; [
    backend
    common
    frontend
  ];
}
