{ pkgs, ... }:
# flake or overlay
{
  mcp-hub = pkgs.buildNpmPackage rec {
    pname = "mcp-hub";
    version = "0.1.0"; # use the version you want

    # 1) If the repo is a flake input:
    # src = mcphub-hub;  # or mcphub-nvim's separate hub repo if you have it

    # 2) If building from npm registry tarball:
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/mcp-hub/-/mcp-hub-${version}.tgz";
      sha256 = "";
    };

    npmDepsHash = "";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      # npm places the bin under node_modules/.bin/mcp-hub
      ln -s $PWD/node_modules/.bin/mcp-hub $out/bin/mcp-hub
      runHook postInstall
    '';
  };
}
