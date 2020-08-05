{ pkgs, stdenv, lib, haskellLib }:

project:

let
  coverageReports = lib.mapAttrsToList (n: package: package.coverageReport) project;
  sources = lib.mapAttrsToList (n: package: package.src) project;
in
stdenv.mkDerivation {
  name = "coverage-report";

  phases = ["buildPhase"];

  buildInputs = (with pkgs; [
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

    ${with lib; concatStringsSep "\n" (mapAttrsToList (n: package: ''
      identifier="${package.identifier.name}-${package.identifier.version}"
      report=${package.coverageReport}
      tix="$report/share/hpc/tix/$identifier/$identifier.tix"
      hpcSumCmd+=("$tix")

      # Copy mix and tix information over from each report
      cp -R $report/share/hpc/mix/* $out/share/hpc/mix
      cp -R $report/share/hpc/tix/* $out/share/hpc/tix
    '') project)}

    # TODO insert project-wide HTML page here

    eval "''${hpcSumCmd[@]}"
  '';
}
