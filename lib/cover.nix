{ stdenv, lib, haskellLib }:
{ ghc, name, src, testDerivations, toCoverDerivations, excludedModules ? [] }:

let
  buildWithCoverage = builtins.map (d: d.covered);

  tests = buildWithCoverage testDerivations;
  covering = buildWithCoverage toCoverDerivations;

  coverageChecks = builtins.map (d: haskellLib.checkWithCoverage d) (builtins.filter (d: d.config.doCheck) tests);

in stdenv.mkDerivation {
  name = (name + "-coverage");

  inherit src;

  phases = ["buildPhase"];

  # If doCheck or doCrossCheck are false we may still build this
  # component and we want it to quietly succeed.
  buildPhase = ''
    runHook preCheck

    mkdir $out

    findMixDirs() {
      find $1 -iwholename "*/hpc/vanilla/mix" -exec find {} -maxdepth 1 -type d -iwholename "*/mix/*" \; -quit
    }

    tixFile=all.tix

    hpcSumCmd=("${ghc}/bin/hpc" "sum" "--union" "--output=$tixFile")
    for check in ${lib.concatStringsSep " " coverageChecks}; do
      for tix in $(find $check -name '*.tix' -print); do
        hpcSumCmd+=("$tix")
      done
    done
    for exclude in $excludedModules; do
      hpcSumCmd+=("--exclude=$exclude")
    done
    echo "''${hpcSumCmd[@]}"
    eval "''${hpcSumCmd[@]}"

    hpcMarkupCmd=("${ghc}/bin/hpc" "markup" "$tixFile" "--destdir=$out" "--srcdir=$src")
    for component in ${lib.concatStringsSep " " (tests ++ covering)}; do
      for mixDir in $(findMixDirs $component); do
        hpcMarkupCmd+=("--hpcdir=$mixDir")
      done
    done
    for exclude in $excludedModules; do
      hpcMarkupCmd+=("--exclude=$exclude")
    done
    echo "''${hpcMarkupCmd[@]}"
    eval "''${hpcMarkupCmd[@]}"

    runHook postCheck
  '';
}
