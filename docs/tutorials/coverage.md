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

This will generate a coverage report for the package you requested.
The directory tree will look something like this:

```
/nix/store/...-my-project-0.1.0.0-coverage-report/
└── share
    └── hpc
        ├── mix
        │   ├── my-library-0.1.0.0
        │   │   └── my-library-0.1.0.0-ERSaOroBZhe9awsoBkhmcV
        │   │       ├── My.Lib.Config.mix
        │   │       ├── My.Lib.Types.mix
        │   │       └── My.Lib.Util.mix
        │   └── my-test-1
        │       ├── Spec.mix
        │       └── Main.mix
        ├── tix
        │   ├── my-library-0.1.0.0
        │   │   └── my-library-0.1.0.0.tix
        │   └── my-test-1
        │       └── my-test-1.tix
        └── html
            ├── my-library-0.1.0.0
            │   ├── my-library-0.1.0.0-ERSaOroBZhe9awsoBkhmcV
            │   │   ├── My.Lib.Config.hs.html
            │   │   ├── My.Lib.Types.hs.html
            │   │   └── My.Lib.Util.hs.html
            │   ├── hpc_index_alt.html
            │   ├── hpc_index_exp.html
            │   ├── hpc_index_fun.html
            │   └── hpc_index.html
            └── my-test-1
                ├── my-library-0.1.0.0-ERSaOroBZhe9awsoBkhmcV
                │   ├── My.Lib.Config.hs.html
                │   ├── My.Lib.Types.hs.html
                │   └── My.Lib.Util.hs.html
                ├── hpc_index_alt.html
                ├── hpc_index_exp.html
                ├── hpc_index_fun.html
                └── hpc_index.html
```

- The hpc artifacts generated live in the `mix` and `tix` directories.
- Marked-up reports live in the `html` directory. 
  - `html/$library-$version/hpc_index.html` is the report of how much
    that library was covered by the tests.
  - `html/$test/hpc_index.html` is the report of how much that test
    contributed towards the library coverage total.

## Project-wide

```bash
nix-build default.nix -A projectCoverageReport
```

This will generate a coverage report for all the local packages in
your project, the directory tree will look something like this:

```bash
/nix/store/...-coverage-report
└── share
    └── hpc
        ├── mix
        │   ├── my-library-0.1.0.0
        │   │   └── my-library-0.1.0.0-ERSaOroBZhe9awsoBkhmcV
        │   │       ├── My.Lib.Config.mix
        │   │       ├── My.Lib.Types.mix
        │   │       └── My.Lib.Util.mix
        │   ├── my-test-1
        │   │   ├── Spec.mix
        │   │   └── Main.mix
        │   ├── other-library-0.1.0.0
        │   │   └── other-library-0.1.0.0-48EVZBwW9Kj29VTaRMhBDf
        │   │       ├── Other.Lib.A.mix
        │   │       └── Other.Lib.B.mix
        │   └── other-test-1
        │       ├── Spec.mix
        │       └── Main.mix
        ├── tix
        │   ├── all
        │   │   └── all.tix
        │   ├── my-library-0.1.0.0
        │   │   └── my-library-0.1.0.0.tix
        │   ├── my-test-1
        │   │   └── my-test-1.tix
        │   ├── other-library-0.1.0.0
        │   │   └── other-library-0.1.0.0.tix
        │   └── other-test-1 
        │       └── other-test-1.tix
        └── html
            ├── my-library-0.1.0.0
            │   ├── my-library-0.1.0.0-ERSaOroBZhe9awsoBkhmcV
            │   │   ├── My.Lib.Config.hs.html
            │   │   ├── My.Lib.Types.hs.html
            │   │   └── My.Lib.Util.hs.html
            │   ├── hpc_index_alt.html
            │   ├── hpc_index_exp.html
            │   ├── hpc_index_fun.html
            │   └── hpc_index.html
            ├── my-test-1
            │   ├── my-library-0.1.0.0-ERSaOroBZhe9awsoBkhmcV
            │   │   ├── My.Lib.Config.hs.html
            │   │   ├── My.Lib.Types.hs.html
            │   │   └── My.Lib.Util.hs.html
            │   ├── hpc_index_alt.html
            │   ├── hpc_index_exp.html
            │   ├── hpc_index_fun.html
            │   └── hpc_index.html
            ├── other-libray-0.1.0.0
            │   ├── other-library-0.1.0.0-48EVZBwW9Kj29VTaRMhBDf
            │   │   ├── Other.Lib.A.hs.html
            │   │   └── Other.Lib.B.hs.html
            │   ├── hpc_index_alt.html
            │   ├── hpc_index_exp.html
            │   ├── hpc_index_fun.html
            │   └── hpc_index.html
            ├── other-test-1
            │   ├── other-library-0.1.0.0-48EVZBwW9Kj29VTaRMhBDf
            │   │   ├── Other.Lib.A.hs.html
            │   │   └── Other.Lib.B.hs.html
            │   ├── hpc_index_alt.html
            │   ├── hpc_index_exp.html
            │   ├── hpc_index_fun.html
            │   └── hpc_index.html
            └── index.html
```

Of particular interest:
  - "all" is a synthetic test target that sums the test coverage
    information from all of your test suites.
  - `all/index.html` is the HTML coverage report for the entire
    project.
