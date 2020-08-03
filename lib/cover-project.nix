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
    mkdir -p $out/share/hpc/mix/

    findMixDir() {
      find $1 -iwholename "*/hpc/vanilla/mix" -exec find {} -maxdepth 1 -type d -iwholename "*/mix/*" \; -quit
    }

    findCabalFile() {
      find $1 -iname "*.cabal" -print -quit
    }

    # Create tix file with test run information for all packages
    tixFile="$out/share/hpc/tix/all/all.tix"
    hpcSumCmd=("hpc" "sum" "--union" "--output=$tixFile")
    for report in ${lib.concatStringsSep " " coverageReports}; do
      for tix in $(find $report -iwholename "*.tix" -type f); do
        hpcSumCmd+=("$tix")
      done

      # Copy mix and tix information over from each report
      cp -R $report/share/hpc/mix/* $out/share/hpc/mix
      cp -R $report/share/hpc/tix/* $out/share/hpc/tix
    done

    eval "''${hpcSumCmd[@]}"
  '';
}
