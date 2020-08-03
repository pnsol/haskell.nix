{ pkgs, stdenv, lib, haskellLib }:

projects:

let
  buildWithCoverage = builtins.map (d: d.covered);
  runCheck = builtins.map (d: haskellLib.check d);

  # drvs' = buildWithCoverage drvs;
  # drvSources = builtins.map (d: d.src.outPath) drvs;
  # testsWithCoverage = buildWithCoverage tests;
  # checks' = runCheck testsWithCoverage;

  projects' = builtins.map (p:
    rec {
      name = p.name;
      drv = p.drv.covered;
      testsWithCoverage = buildWithCoverage p.tests;
      checks = runCheck testsWithCoverage;
    }
  ) projects;

  doThis = p: ''
    mkdir -p $out/share/hpc/mix/${p.name}
    mkdir -p $out/share/hpc/tix/${p.name}

    for drv in ${lib.concatStringsSep " " ([ p.drv ] ++ p.testsWithCoverage)}; do
      # Copy over mix files
      local mixDir=$(findMixDir $drv)
      cp -R $mixDir/* $out/share/hpc/mix/${p.name}
    done

    # Exclude test modules from tix file
    excludedModules=('"Main"')
    local drv=${p.drv.src.outPath}
    # Exclude test modules
    local cabalFile=$(findCabalFile $drv)
    for module in $(${pkgs.cq}/bin/cq $cabalFile testModules | ${pkgs.jq}/bin/jq ".[]"); do
      excludedModules+=("$module")
    done
    echo "''${excludedModules[@]}"

    hpcSumCmdBase=("hpc" "sum" "--union")
    for exclude in ''${excludedModules[@]}; do
      hpcSumCmdBase+=("--exclude=$exclude")
    done

    for check in ${lib.concatStringsSep " " p.checks}; do
      pushd $check/share/hpc/tix
      
      for tixFileRel in $(find . -iwholename "*.tix" -type f); do
        set -x
        mkdir -p $out/share/hpc/tix/${p.name}/$(dirname $tixFileRel)
        cp $tixFileRel $out/share/hpc/tix/${p.name}/$tixFileRel.pre-exclude
        
        local hpcSumCmd=("''${hpcSumCmdBase[@]}")
        hpcSumCmd+=("--output=$out/share/hpc/tix/${p.name}/$tixFileRel" "$tixFileRel")
        echo "''${hpcSumCmd[@]}"
        eval "''${hpcSumCmd[@]}"
      done

      popd
    done
  '';

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

    # Copy over the mix and tix files for each package
    ${lib.concatStringsSep "\n" (builtins.map doThis projects')}

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
