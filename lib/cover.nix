{ stdenv, lib, haskellLib }:
{ ghc, pkgs, name, src, testDerivations, toCoverDerivations }:

let
  buildWithCoverage = builtins.map (d: d.covered);

  tests = buildWithCoverage testDerivations;
  covering = buildWithCoverage toCoverDerivations;

  coverageChecks = builtins.map (d: haskellLib.check d) (builtins.filter (d: d.config.doCheck) tests);

in stdenv.mkDerivation {
  name = (name + "-coverage");

  inherit src;

  phases = ["buildPhase"];

  buildInputs = (with pkgs; [
    git
  ]) ++ (with pkgs.haskellPackages; [
    hpc-coveralls
  ]);

  # If doCheck or doCrossCheck are false we may still build this
  # component and we want it to quietly succeed.
  buildPhase = ''
    runHook preCheck

    mkdir $out
    mkdir -p $out/share/hpc
    mkdir -p $out/share/hpc/mix
    mkdir -p $out/share/hpc/tix

    findMixDir() {
      find $1 -iwholename "*/hpc/vanilla/mix" -exec find {} -maxdepth 1 -type d -iwholename "*/mix/*" \; -quit
    }

    tixFile=all.tix

    cabalFile=$(find $src -iname "*.cabal" -print -quit)
    excludedModules=("Main")
    for module in $(${pkgs.cq}/bin/cq $cabalFile testModules | ${pkgs.jq}/bin/jq ".[]"); do
      excludedModules+=("$module")
    done
    echo "done"
    echo "''${excludedModules[@]}"

    hpcSumCmd=("${ghc}/bin/hpc" "sum" "--union" "--output=$tixFile")
    for check in ${lib.concatStringsSep " " coverageChecks}; do
      for tix in $(find $check -name '*.tix' -print); do
        hpcSumCmd+=("$tix")
      done
      cp -R $check/share/hpc/tix/* $out/share/hpc/tix/
    done
    for exclude in ''${excludedModules[@]}; do
      hpcSumCmd+=("--exclude=$exclude")
    done
    echo "''${hpcSumCmd[@]}"
    eval "''${hpcSumCmd[@]}"

    hpcMarkupCmd=("${ghc}/bin/hpc" "markup" "$tixFile" "--destdir=$out" "--srcdir=$src")
    for component in ${lib.concatStringsSep " " (tests ++ covering)}; do
      echo "COMPONENT IS $component"
      local mixDir=$(findMixDir $component)

      hpcMarkupCmd+=("--hpcdir=$mixDir")
      cp -R $mixDir $out/share/hpc/mix
    done
    for exclude in ''${excludedModules[@]}; do
      hpcMarkupCmd+=("--exclude=$exclude")
    done
    echo "''${hpcMarkupCmd[@]}"
    eval "''${hpcMarkupCmd[@]}"

    mkdir -p $out/share/hpc/tix/all
    cp $tixFile $out/share/hpc/tix/all/all.tix

    cp -r $src/* $out

    runHook postCheck
  '';
}
