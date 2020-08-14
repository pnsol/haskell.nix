# Test a package set
{ stdenv, util, cabalProject', haskellLib, recurseIntoAttrs, testSrc }:

with stdenv.lib;

let
  project = cabalProject' {
    src = testSrc "sublib-docs";
  };

  packages = project.hsPkgs;

in recurseIntoAttrs {
  ifdInputs = {
    inherit (project) plan-nix;
  };
  run = stdenv.mkDerivation {
    name = "sublib-docs-test";

    buildCommand = ''
      exe="${packages.sublib-docs.components.exes.sublib-docs}/bin/sublib-docs${stdenv.hostPlatform.extensions.executable}"

      size=$(command stat --format '%s' "$exe")
      printf "size of executable $exe is $size. \n" >& 2

      # fixme: run on target platform when cross-compiled
      printf "checking whether executable runs... " >& 2
      cat ${haskellLib.check packages.sublib-docs.components.exes.sublib-docs}/test

    '' +
    # Musl and Aarch are statically linked..
    optionalString (!stdenv.hostPlatform.isAarch32 && !stdenv.hostPlatform.isAarch64 && !stdenv.hostPlatform.isMusl) (''
      printf "checking that executable is dynamically linked to system libraries... " >& 2
    '' + optionalString (stdenv.isLinux && !stdenv.hostPlatform.isMusl) ''
      ldd $exe | grep libgmp
    '' + optionalString stdenv.isDarwin ''
      otool -L $exe |grep .dylib
    '') + ''

      printf "Checking that \"all\" component has the programs... " >& 2
      all_exe="${packages.sublib-docs.components.all}/bin/sublib-docs${stdenv.hostPlatform.extensions.executable}"
      test -f "$all_exe"
      echo "$all_exe" >& 2

      # Check that it looks like we have docs
      test -f "${packages.sublib-docs.components.library.doc}/share/doc/sublib-docs/html/Lib.html"
      test -f "${packages.sublib-docs.components.sublibs.slib.doc}/share/doc/slib/html/Slib.html"

      touch $out
    '';

    meta.platforms = platforms.all;

    passthru = {
      # Used for debugging with nix repl
      inherit packages;

      # Used for testing externally with nix-shell (../tests.sh).
      # This just adds cabal-install to the existing shells.
      test-shell = util.addCabalInstall packages.sublib-docs.components.all;
    };
  };
}
