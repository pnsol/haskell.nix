# Coverage

haskell.nix can generate coverage information for your package or
project using Cabal's inbuilt hpc support.

## Pre-requisites

It is currently required that you enable coverage for each library you
want coverage for prior to attempting to generate a coverage report. I
hope to fix this before merging this PR:

```nix
  haskell-nix.cabalProject ({
    src = pkgs.haskell-nix.haskellLib.cleanGit {
      name = "haskell-nix-project";
      src = ./.;
    };
    modules = [
      {
        packages.package-1.components.library.doCoverage = true;
        packages.package-2.components.library.doCoverage = true;
      }
    ];
  });
```

## Per-package

```bash
nix-build default.nix -A $pkg.coverageReport
```

## Project-wide

```bash
nix-build default.nix -A projectCoverageReport
```

This will generate a coverage report for all the local packages in
your project, the directory tree will look something like this:

```bash
```

"all" is a synthetic test target that sums the test coverage
information from all of your test suites.

all/index.html is the HTML coverage report for the project
