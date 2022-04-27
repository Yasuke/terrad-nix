{ pkgs ? import ./deps/nixpkgs {}
, buildGoModule ? pkgs.buildGoModule
, fetchFromGitHub ? pkgs.fetchFromGitHub
, coreutils ? pkgs.coreutils
}:

buildGoModule rec {
  name = "core";
  version = "0.6.x";

  src = fetchFromGitHub {
    owner = "terra-money";
    repo = "core";
    rev = "61f08cb3c38854103eab39be37fbcd9b6f3be91a";
    sha256 = "1w1zc8b8bhpii3hbyf74f15s572h8c5m1i284vzb9hqwa43schdl";
  };

  vendorSha256 = "1frvi0mj22j4n22dsl532s8d5hc3rx677a9anv7fkz3n6j3z6a6v";

  postConfigure = ''
    chmod -R +w vendor
    sed -i 's|/bin/stty|${coreutils}/bin/stty|' vendor/github.com/bgentry/speakeasy/speakeasy_unix.go
  '';

  # Not entirely sure why we need this: https://github.com/NixOS/patchelf/issues/99#issuecomment-355536880
  dontStrip = true;
  # Install pre-packaged binary shared library... TODO: Find a correct way to build from source
  postInstall = ''
    mkdir -p $out/lib
    cp vendor/github.com/CosmWasm/wasmvm/api/libwasmvm.so $out/lib/

    patchelf --print-rpath $out/bin/terrad \
    | sed "s|$(pwd)/vendor/github.com/CosmWasm/wasmvm/api|$out/lib|" \
    | xargs patchelf $out/bin/terrad --set-rpath
  '';
}
