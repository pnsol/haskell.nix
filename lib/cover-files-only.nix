{ pkgs, stdenv, lib, haskellLib }:

project:

let
  coverageReports = lib.mapAttrsToList (n: package: package.coverageReport) project;
in
stdenv.mkDerivation {
  name = "coverage-report";

  phases = ["buildPhase"];

  buildInputs = (with pkgs.haskellPackages; [
    ghc
  ]);

  buildPhase = ''
    mkdir -p $out/share/hpc/tix/all

    findMixDir() {
      find $1 -iwholename "*/hpc/vanilla/mix" -exec find {} -maxdepth 1 -type d -iwholename "*/mix/*" \; -quit
    }

    findCabalFile() {
      find $1 -iname "*.cabal" -print -quit
    }

    
    echo "Project coverage reports are: "
    for report in ${lib.concatStringsSep " " coverageReports}; do
      echo $report
    done
  '';

    # # Generate combined tix file for all packages
    # excludedModules=("Main")
    # for drv in ${lib.concatStringsSep " " allSrcs}; do
    #   # Exclude test modules
    #   local cabalFile=$(findCabalFile $drv)
    #   for module in $(${pkgs.cq}/bin/cq $cabalFile testModules | ${pkgs.jq}/bin/jq ".[]"); do
    #     excludedModules+=("$module")
    #   done
    # done
    # echo "''${excludedModules[@]}"

    # tixFile="$out/share/hpc/tix/all/all.tix"
    # hpcSumCmd=("hpc" "sum" "--union" "--output=$tixFile")
    # for check in ${lib.concatStringsSep " " allChecks}; do
    #   for tix in $(find $check -name '*.tix' -print); do
    #     hpcSumCmd+=("$tix")
    #   done
    # done
    # for exclude in ''${excludedModules[@]}; do
    #   hpcSumCmd+=("--exclude=$exclude")
    # done
    # echo "''${hpcSumCmd[@]}"
    # eval "''${hpcSumCmd[@]}"

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
