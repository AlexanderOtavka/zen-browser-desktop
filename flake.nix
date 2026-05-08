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
          # marionette_driver.processhandler imports psutil at module load;
          # without it `./mach test` crashes before launching any test.
          psutil
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
          # pkgs.watchman — disabled on aarch64-darwin: watchman pulls
          #   in fbthrift, whose thrift1 codegen binary is SIGKILL'd
          #   (code 137) during eden_config codegen — looks like an
          #   ad-hoc signing issue in the nixpkgs build. mach falls
          #   back to a manual file scan without it; re-enable once
          #   nixpkgs ships a usable thrift1.
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

            # Node ignores SSL_CERT_FILE and uses its own bundled Mozilla
            # CA store, which doesn't include corporate MITM roots like
            # Zscaler. Point NODE_EXTRA_CA_CERTS at the shell's SSL_CERT_FILE
            # if set (respects whatever extra roots the user has trusted —
            # e.g. homebrew's /opt/homebrew/etc/openssl@3/cert.pem with the
            # Zscaler root merged in), otherwise fall back to nix cacert.
            # Without this, `surfer download` fails with
            # "unable to get local issuer certificate" behind Zscaler.
            if [ -r "$SSL_CERT_FILE" ]; then
              export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"
            else
              export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            fi

            # Once `mach bootstrap` has fetched Firefox's clang toolchain,
            # prefer it over nix's clang-wrapper. The wrapper mangles a few
            # flags (notably preprocessing of `.S` files — `__APPLE__` stops
            # firing, which breaks engine/config/external/icu/data/icu_data.S).
            # Guarded so a fresh checkout that hasn't bootstrapped yet still
            # enters the shell cleanly.
            if [ -x "$HOME/.mozbuild/clang/bin/clang" ]; then
              export CC="$HOME/.mozbuild/clang/bin/clang"
              export CXX="$HOME/.mozbuild/clang/bin/clang++"
              # mach's configure snapshots $AS and inherits nix's `as`
              # (clang-wrapper'd) by default. That `as` assembles .S files
              # without running cpp, leaving `#if defined(__APPLE__)` blocks
              # unexpanded and tripping the icu_data.S errors. Setting AS to
              # mach's clang alone doesn't work either: it preprocesses but
              # has no -isysroot, so `#include <mach/machine/vm_param.h>` in
              # libffi's sysv.S can't find the macOS SDK. Unset AS entirely
              # so mach falls back to using CC (which has -isysroot baked in)
              # for .S assembly.
              unset AS
            fi

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

            # zen-build — follows docs.zen-browser.app/contribute/desktop/building.
            # Runs first-time setup (npm ci + npm run init) on demand, then
            # the two steps every full rebuild needs: sync the en-US language
            # pack into engine/, then `npm run build`. After the first full
            # build, use `zen-build-ui` for JS-only changes.
            zen-build() {
              set -e
              if [ ! -x node_modules/.bin/surfer ]; then
                echo "→ npm ci"
                npm ci
              fi
              if [ ! -d engine ] || [ ! -f engine/mozconfig ]; then
                echo "→ npm run init"
                npm run init
              fi
              echo "→ scripts/update_en_US_packs.py"
                # Required after every surfer reset/import: copies
                # locales/en-US/browser/browser/zen-*.ftl into
                # engine/browser/locales/en-US/. Without this, chrome UI
                # renders with empty strings for anything Zen-specific.
              python3 scripts/update_en_US_packs.py
              echo "→ npm run build"
              npm run build
              set +e
              echo "✓ zen-build complete. Run 'npm start' to launch."
            }

            zen-build-ui() {
              set -e
              python3 scripts/update_en_US_packs.py
              npm run build:ui
              set +e
            }

            # Export so the helpers are callable from `nix develop --command
            # bash -c 'zen-build'`, not just interactive shells.
            export -f zen-build zen-build-ui

            echo ""
            echo "Zen Browser dev shell ready."
            echo "  node    $(node --version)"
            echo "  python  $(python3 --version 2>&1)"
            echo "  rustc   $(rustc --version)"
            echo "  tar     $(tar --version | head -1)"
            echo ""
            echo "Build + run:"
            echo "  zen-build       # full rebuild (handles first-time setup too)"
            echo "  zen-build-ui    # JS-only incremental rebuild"
            echo "  npm start       # launch the built browser"
            echo ""
            echo "Running tests:"
            echo "  npm test                  # all suites under src/zen/tests"
            echo "  npm test -- tabs          # one suite (dir name under src/zen/tests)"
            echo "  npm test -- --jsdebugger  # extra args forward to ./mach test"
            echo "  npm run test:dbg          # opens jsdebugger, breaks on failure"
            echo "  (cd engine && ./mach test zen/tests/tabs)       # direct mach invocation"
            echo "  (cd engine && ./mach mochitest --help)          # per-harness flags"
          '';
        } // surferEnv);

        # Convenience: `nix fmt` runs nixpkgs-fmt.
        formatter = pkgs.nixpkgs-fmt;
      });
}
