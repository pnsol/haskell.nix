{ stdenv, lib, haskellLib, pkgs }:

{ name, library, tests }:

let
  buildWithCoverage = builtins.map (d: d.covered);
  runCheck = builtins.map (d: haskellLib.check d);

  libraryCovered    = library.covered;
  testsWithCoverage = buildWithCoverage tests;
  checks            = runCheck testsWithCoverage;

in stdenv.mkDerivation {
  name = (name + "-coverage-report");

  phases = ["buildPhase"];

  buildInputs = (with pkgs; [ ghc cq jq ]);

  buildPhase = ''
    findMixDir() {
      find $1 -iwholename "*/hpc/vanilla/mix" -exec find {} -maxdepth 1 -type d -iwholename "*/mix/*" \; -quit
    }

    findCabalFile() {
      find $1 -iname "*.cabal" -print -quit
    }

    mkdir -p $out/share/hpc/mix/${name}
    mkdir -p $out/share/hpc/tix/${name}

    for drv in ${lib.concatStringsSep " " ([ libraryCovered ] ++ testsWithCoverage)}; do
      # Copy over mix files
      local mixDir=$(findMixDir $drv)
      cp -R $mixDir/* $out/share/hpc/mix/${name}
    done

    # Exclude test modules from tix file
    excludedModules=('"Main"')
    local drv=${libraryCovered.src.outPath}
    # Exclude test modules
    local cabalFile=$(findCabalFile $drv)
    for module in $(cq $cabalFile testModules | jq ".[]"); do
      excludedModules+=("$module")
    done
    echo "''${excludedModules[@]}"

    hpcSumCmdBase=("hpc" "sum" "--union")
    for exclude in ''${excludedModules[@]}; do
      hpcSumCmdBase+=("--exclude=$exclude")
    done

    for check in ${lib.concatStringsSep " " checks}; do
      pushd $check/share/hpc/tix
      
      # Find each tix file (relative to check directory above)
      for tixFileRel in $(find . -iwholename "*.tix" -type f); do
        # Output tix file as-is with suffix
        mkdir -p $out/share/hpc/tix/${name}/$(dirname $tixFileRel)
        cp $tixFileRel $out/share/hpc/tix/${name}/$tixFileRel.pre-exclude
        
        # Output tix file with test modules excluded
        local hpcSumCmd=("''${hpcSumCmdBase[@]}")
        hpcSumCmd+=("--output=$out/share/hpc/tix/${name}/$tixFileRel" "$tixFileRel")
        echo "''${hpcSumCmd[@]}"
        eval "''${hpcSumCmd[@]}"
      done

      popd
    done

    # hpcMarkupCmd=("hpc" "markup" "$tixFile" "--destdir=$out" "--srcdir=$src")
    # for component in ; do
    #   echo "COMPONENT IS $component"
    #   local mixDir=$(findMixDir $component)

    #   hpcMarkupCmd+=("--hpcdir=$mixDir")
    #   cp -R $mixDir $out/share/hpc/mix
    # done
    # for exclude in ''${excludedModules[@]}; do
    #   hpcMarkupCmd+=("--exclude=$exclude")
    # done
    # echo "''${hpcMarkupCmd[@]}"
    # eval "''${hpcMarkupCmd[@]}"

    # mkdir -p $out/share/hpc/tix/all
    # cp $tixFile $out/share/hpc/tix/all/all.tix

    # cp -r $src/* $out
  '';
}
