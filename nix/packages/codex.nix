{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  ncurses,
  jq,
}:
let
  version = "0.162.0";
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-WAnukKnDtZ1Di7JmOu+gtD2G+CVDi2XUUEsx+CNDYos=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-1Hpfoh4DehuFcpuIwjj/PaipVvyfta05dnFEKOf7K9o=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-T1c5RMHSBZEJ11ovTQzJwDaXKIIkpeQHcXqd6Y/AEMU=";
    };
  };
  release = releases.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${release.target}.tar.gz";
    inherit (release) hash;
  };

  sourceRoot = ".";
  dontBuild = true;
  # Keep Darwin signatures intact; Linux helpers need Nix runtime paths.
  dontFixup = stdenvNoCC.hostPlatform.isDarwin;
  dontStrip = true;
  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    ncurses
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a bin codex-path codex-resources codex-package.json "$out/"
    runHook postInstall
  '';

  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  nativeInstallCheckInputs = [ jq ];
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/codex-home"
    mkdir -p "$HOME"
    test "$("$out/bin/codex" --version)" = "codex-cli ${version}"
    "$out/bin/codex" completion bash > /dev/null
    jq -e --arg version '${version}' --arg target '${release.target}' '
      .layoutVersion == 1 and .version == $version and .target == $target
      and .entrypoint == "bin/codex" and .resourcesDir == "codex-resources"
      and .pathDir == "codex-path"
    ' "$out/codex-package.json" > /dev/null
    test -x "$out/bin/codex-code-mode-host"
    test -x "$out/codex-path/rg"
    test -x "$out/codex-resources/zsh/bin/zsh"
    test -x "$out/codex-resources/voice/bin/codex-voice-host"
    "$out/bin/codex-code-mode-host" --help > /dev/null
    "$out/codex-path/rg" --version > /dev/null
    "$out/codex-resources/zsh/bin/zsh" --version > /dev/null
    ${lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
      test -x "$out/codex-resources/bwrap"
      "$out/codex-resources/bwrap" --version > /dev/null
    ''}
    runHook postInstallCheck
  '';

  meta = {
    description = "OpenAI Codex CLI with its upstream runtime bundle";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames releases;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
