{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  jq,
  nodejs,
  makeWrapper,
  autoPatchelfHook,
  stdenv,
}:

let
  pname = "pi-coding-agent";
  version = "0.84.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-ppoYWWAX6RlV/Q/Wd75p+rW26gHVsGIHvO407hUivCA=";
  };

  # npm-shrinkwrap.json as published is missing `integrity` for these sibling
  # @earendil-works/* workspace packages (an artifact of upstream's monorepo
  # build), which makes fetchNpmDeps/prefetch-npm-deps refuse to process it.
  # Patch the missing hashes in before fetching deps.
  missingIntegrity = {
    "@earendil-works/pi-agent-core" = "sha512-evyzXYWCLQGmcaBYHlmSku02r8qoN4SGI60GZABo6iV+H+nqX+P9ud8fEZ4GmRq9mUSREvvfX+w9dA9ThF9C6w==";
    "@earendil-works/pi-ai" = "sha512-wMsAdJMxuNri08vLqTyYVI201DQQezGhPSTkzYsHdw5dYX3rCNwEmSvpaAwhi7ELKI/2tE/CEgSWg/6iRxSgdQ==";
    "@earendil-works/pi-client" = "sha512-/V5hGHE4Zq+jG0GtwIB9PyBUOGd6gBLZ7lkQYFKchKnxYHeH3rmWC5xw4kpnZKKBuBuFTdLVbU9vEjlAGMMb2A==";
    "@earendil-works/pi-protocol" = "sha512-Ox1pciyeSPGEEUcxvR0/dJcrY7C6hrEGA8y71rOsvSIUlXN1Cbp/be/eoL71OGDBk5O97TeQPfWN6Ju/2Ehjww==";
    "@earendil-works/pi-telemetry" = "sha512-180/xGJtsq7IoR3p9EKWjRd0e9M4DkxInhlo9xyD7prDC7Qrhqq+nhvwrW0lFjPfXcEI2FSHmGCSyvSJE9GsaQ==";
    "@earendil-works/pi-tui" = "sha512-udeXFbgEhJ6JiB0uguwNVNkDy2FENfmtQwPcY+/iJ8GWeq18wkal1tKqa5YyeH0IqtX1vG0cGh8zfSYzyzVuLA==";
  };

  patchedSrc = runCommand "${pname}-${version}-patched-src" { nativeBuildInputs = [ jq ]; } ''
    mkdir -p $out
    tar -xzf ${src} -C $out --strip-components=1

    jq --argjson extra ${lib.escapeShellArg (builtins.toJSON missingIntegrity)} '
      .packages |= with_entries(
        ($extra[(.key | sub(".*node_modules/"; ""))]) as $i
        | if $i then .value.integrity = $i else . end
      )
    ' $out/npm-shrinkwrap.json > $out/npm-shrinkwrap.json.tmp
    mv $out/npm-shrinkwrap.json.tmp $out/npm-shrinkwrap.json

    # devDependencies (typescript, vitest, @types/*, ...) are almost entirely
    # absent from npm-shrinkwrap.json (only @types/node is present), so `npm
    # ci` refuses to install without live network access to resolve them.
    # None are needed: dist/ ships prebuilt and dontNpmBuild = true below.
    jq 'del(.devDependencies)' $out/package.json > $out/package.json.tmp
    mv $out/package.json.tmp $out/package.json
  '';
in
buildNpmPackage {
  inherit pname version;
  src = patchedSrc;

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-WwrhgBfs8SvKWziwmHO/RBlB/eE6vMmDZxE6iMZncY4=";
  npmFlags = [ "--omit=dev" ];

  dontNpmBuild = true;

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi $out/bin
    cp -r . $out/lib/pi
    chmod +x $out/lib/pi/dist/cli.js

    makeWrapper ${nodejs}/bin/node $out/bin/pi \
      --add-flags $out/lib/pi/dist/cli.js

    runHook postInstall
  '';

  meta = {
    description = "Terminal-based AI coding agent (npm distribution)";
    homepage = "https://github.com/earendil-works/pi-mono";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.platforms.unix;
  };
}
