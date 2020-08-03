{ pkgs, stdenv, lib, haskellLib }:

projects:

let
  buildWithCoverage = builtins.map (d: d.covered);
  runCheck = builtins.map (d: haskellLib.check d);

  # drvs' = buildWithCoverage drvs;
  # drvSources = builtins.map (d: d.src.outPath) drvs;
  # testsWithCoverage = buildWithCoverage tests;
  # checks' = runCheck testsWithCoverage;
  drvs' = null;
  drvSources = null;
  testsWithCoverage = null;
  checks' = null;

  projects' = builtins.map (p:
    rec {
      name = p.name;
      drv = p.drv.covered;
      testsWithCoverage = buildWithCoverage p.tests;
      checks = runCheck testsWithCoverage;
    }
  ) projects;

  doThis = p: ''
    mkdir $out/share/hpc/mix/${p.name}

    for drv in ${lib.concatStringsSep " " ([ p.drv ] ++ p.testsWithCoverage)}; do
      # Copy over mix files
      local mixDir=$(findMixDir $drv)
      echo "MixDir: $mixDir"
      cp -R $mixDir/* $out/share/hpc/mix/${p.name}
    done
  '';

in stdenv.mkDerivation {
  name = "coverage-report";

  inherit checks' drvs' drvSources;

  phases = ["buildPhase"];

  buildInputs = (with pkgs.haskellPackages; [
    ghc
  ]);

  buildPhase = ''
    mkdir -p $out/share/hpc/mix
    mkdir -p $out/share/hpc/tix
    mkdir -p $out/share/hpc/tix/all

    findMixDir() {
      find $1 -iwholename "*/hpc/vanilla/mix" -exec find {} -maxdepth 1 -type d -iwholename "*/mix/*" \; -quit
    }

    findCabalFile() {
      find $1 -iname "*.cabal" -print -quit
    }

    ${lib.concatStringsSep "\n" (builtins.map doThis projects')}

  '';

    # for check in ${lib.concatStringsSep " " checks'}; do
    #   cp -R $check/share/hpc/tix/* $out/share/hpc/tix
    # done

    # # For each derivation to generate coverage for
    # for drv in ${lib.concatStringsSep " " (drvs' ++ testsWithCoverage)}; do
    #   # Copy over mix files
    #   local mixDir=$(findMixDir $drv)
    #   echo "MixDir: $mixDir"
    #   cp -R $mixDir/* $out/share/hpc/mix/
    # done

    # excludedModules=("Main")
    # for drv in ${lib.concatStringsSep " " drvSources}; do
    #   # Exclude test modules
    #   local cabalFile=$(findCabalFile $drv)
    #   for module in $(${pkgs.cq}/bin/cq $cabalFile testModules | ${pkgs.jq}/bin/jq ".[]"); do
    #     excludedModules+=("$module")
    #   done
    # done
    # echo "''${excludedModules[@]}"

    # tixFile="$out/share/hpc/tix/all/all.tix"
    # hpcSumCmd=("hpc" "sum" "--union" "--output=$tixFile")
    # for check in ${lib.concatStringsSep " " checks'}; do
    #   for tix in $(find $check -name '*.tix' -print); do
    #     hpcSumCmd+=("$tix")
    #   done
    # done
    # for exclude in ''${excludedModules[@]}; do
    #   hpcSumCmd+=("--exclude=$exclude")
    # done
    # echo "''${hpcSumCmd[@]}"
    # eval "''${hpcSumCmd[@]}"
}
