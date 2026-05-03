{
  description = "Zen Browser build environment (Firefox-based, driven by surfer + mach)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
          # Firefox source includes non-free components; the build tooling is
          # fine but mach can pull unfree binaries into ~/.mozbuild.
          config.allowUnfree = true;
        };

        # Pinned by .rust-toolchain (1.90). aarch64-apple-darwin is needed by
        # tools/ffprefs and matches the mozconfig target arch.
        rustToolchain = pkgs.rust-bin.stable."1.90.0".default.override {
          targets = [
            "aarch64-apple-darwin"
            "x86_64-apple-darwin"
            "x86_64-unknown-linux-gnu"
          ];
          extensions = [ "rust-src" ];
        };

        # Pinned by .python-version (3.11). mach is picky — newer Pythons fail.
        python = pkgs.python311;
        pythonEnv = python.withPackages (ps: with ps; [
          # from requirements.txt — these satisfy scripts/ directly.
          click
          mypy-extensions
          packaging
          pathspec
          platformdirs
          pycodestyle
          requests
          # mach bootstraps its own virtualenvs; don't add pip/setuptools here
          # (on recent nixpkgs py311 pip drags in sphinx 9.1.0 which requires
          # python ≥ 3.12 and breaks evaluation).
          # zstandard is needed by mach artifact-toolchain for the .zst files
          # (bootstrap fetches clang/rust as zstd tarballs).
          zstandard
        ]);

        # Pinned by .nvmrc (22).
        nodejs = pkgs.nodejs_22;

        isDarwin = pkgs.stdenv.isDarwin;

        commonInputs = [
          nodejs
          pythonEnv
          rustToolchain
          pkgs.gnutar           # mach's tar invocations assume GNU tar
          pkgs.mercurial        # mach uses hg for some toolchain fetches
          pkgs.watchman         # speeds up mach's file scanning
          pkgs.cairo            # runtime dep surfaced by the plan
          pkgs.pkg-config
          pkgs.git
          pkgs.gnumake
          pkgs.unzip
          pkgs.zip
          pkgs.which
          pkgs.curl
          pkgs.nasm
          pkgs.yasm
        ];

        # On macOS the plan relies on Xcode command-line tools (SDK, clang,
        # codesign). Nix-packaged clang would fight with mach's own toolchain
        # fetch, so we intentionally DON'T add clang/llvm here and instead
        # pass --exclude macos-sdk to `mach bootstrap` per the plan.
        darwinOnly = [ ];

        linuxOnly = with pkgs; [
          # Firefox build deps on Linux. macOS uses Xcode instead.
          gcc
          binutils
          gtk3
          glib
          dbus
          dbus-glib
          libnotify
          alsa-lib
          pulseaudio
          libx11
          libxt
          libxrender
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxtst
          libGL
          mesa
          ffmpeg
        ];

        buildInputs = commonInputs
          ++ pkgs.lib.optionals isDarwin darwinOnly
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux linuxOnly;

        # Surfer wants these to pick the macOS arm64 target. Harmless on
        # Linux (overridden by mach's autodetection there).
        surferEnv = pkgs.lib.optionalAttrs isDarwin {
          SURFER_COMPAT = "aarch64";
          SURFER_PLATFORM = "darwin";
        };
        # On darwin, the default stdenv pins apple-sdk 14.4 — but Firefox 150
        # requires SDK 26.2+. Swap in apple-sdk_26 for the shell's stdenv so
        # SDKROOT/DEVELOPER_DIR point at a sufficiently new SDK.
        mkShell =
          if isDarwin then
            pkgs.mkShell.override { stdenv = pkgs.apple-sdk_26.stdenv or pkgs.stdenv; }
          else
            pkgs.mkShell;
      in
      {
        devShells.default = mkShell ({
          packages = buildInputs;

          # Keep cargo inside the worktree so hermetic runs don't leak into
          # ~/.cargo when devs don't want that. (Comment out to share.)
          # CARGO_HOME = "$PWD/.cargo";

          shellHook = ''
            # Pin $HOME/.mozbuild so mach's toolchain cache is predictable
            # and survives across shells. Has to be exported here (not via a
            # mkShell attr) so $HOME is shell-expanded, not left literal.
            export MOZBUILD_STATE_PATH="$HOME/.mozbuild"

            # Ensure GNU tar wins over BSD tar on macOS. Nix's gnutar
            # already installs as `tar` inside the shell, but make it
            # explicit so any spawned sub-shells inherit the right PATH.
            export PATH="${pkgs.gnutar}/bin:$PATH"

            # Tell mach to use the system (Nix-provided) Python instead of
            # bootstrapping its own. MACH_USE_SYSTEM_PYTHON is deprecated on
            # recent mozilla-central; the new knob is
            # MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE. If a stale shell still
            # has the old var set, mach errors out because the two overlap —
            # scrub it defensively.
            unset MACH_USE_SYSTEM_PYTHON
            export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE=system
            export PYTHON3="${pythonEnv}/bin/python3"

            # Node-gyp etc. want this.
            export npm_config_python="${pythonEnv}/bin/python3"

            ${pkgs.lib.optionalString isDarwin ''
              export SURFER_COMPAT=aarch64
              export SURFER_PLATFORM=darwin

              # mach bootstrap with --exclude macos-sdk relies on Xcode
              # command-line tools being installed on the host. Warn if not.
              if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
                echo "⚠️  Xcode command-line tools are not installed."
                echo "   Run: xcode-select --install"
                echo "   Then: sudo xcodebuild -license accept"
              fi
            ''}

            echo ""
            echo "Zen Browser dev shell ready."
            echo "  node    $(node --version)"
            echo "  python  $(python3 --version 2>&1)"
            echo "  rustc   $(rustc --version)"
            echo "  tar     $(tar --version | head -1)"
            echo ""
            echo "First-time setup (see .claude/plans/get-this-codebase-to-snuggly-stearns.md):"
            echo "  npm ci"
            echo "  npm run surfer -- ci --brand release --display-version 1.19.9b"
            echo "  npm run download"
            echo "  npm run import"
            echo "  (cd engine && ./mach --no-interactive bootstrap \\"
            echo "      --application-choice browser${pkgs.lib.optionalString isDarwin " --exclude macos-sdk"})"
            echo ""
            echo "Build + run:"
            echo "  npm run build"
            echo "  npm start"
            echo ""
            echo "Running tests:"
            echo "  npm test                  # all suites under src/zen/tests"
            echo "  npm test -- tabs          # one suite (dir name under src/zen/tests)"
            echo "  npm test -- --jsdebugger  # extra args forward to ./mach test"
            echo "  npm run test:dbg          # opens jsdebugger, breaks on failure"
            echo "  (cd engine && ./mach test src/zen/tests/tabs)   # direct mach invocation"
            echo "  (cd engine && ./mach mochitest --help)          # per-harness flags"
            echo ""
            echo "  NOTE: the checked-in mozconfig sets --disable-tests (works around a"
            echo "  third_party/zucchini + libc++19 breakage). To actually run tests you"
            echo "  must comment out that line in ./mozconfig and rebuild:"
            echo "      sed -i.bak '/--disable-tests/s/^/# /' mozconfig"
            echo "      npm run build   # relinks with tests enabled"
            echo "  If the zucchini tests fail to compile, also add to mozconfig:"
            echo "      ac_add_options --disable-updater"
            echo "  or patch third_party/zucchini for char_traits<unsigned char>."
          '';
        } // surferEnv);

        # Convenience: `nix fmt` runs nixpkgs-fmt.
        formatter = pkgs.nixpkgs-fmt;
      });
}
