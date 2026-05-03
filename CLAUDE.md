# CLAUDE.md — `zotavka/dev` personal base branch

This branch (`zotavka/dev`) is a personal fork of `upstream/dev`. It exists to
carry local development tooling and cached build outputs that should **never
be included in a PR back to upstream**. Treat it as a long-lived personal base,
not a contribution branch.

## Branch topology

```
upstream/dev
  │
  │  (sync, no local edits)
  ▼
origin/dev                      ← mirror of upstream/dev on the personal fork
  │
  │  (rebase when upstream moves)
  ▼
zotavka/dev                     ← THIS BRANCH: adds flake.nix, flake.lock,
  │                               CLAUDE.md; also holds gitignored build
  │                               artifacts (engine/, node_modules/) as a
  │                               working-tree cache
  │
  │  (branch off for feature work)
  ▼
zotavka/dev-gh-123-feature      ← feature TEST branch. Uses local dev tooling
  │                               (flake + warm engine/node_modules cache).
  │                               Never pushed as a PR.
  │
  │  (cherry-pick just the code changes — NOT flake/CLAUDE.md/engine/etc.)
  ▼
gh-123-feature                  ← clean PR branch against upstream/dev.
                                  No local dev config.
```

## What lives on this branch

Committed:

- `flake.nix`, `flake.lock` — Nix dev shell pinning Rust 1.90, Python 3.11,
  Node 22, and the rest of the mach/surfer toolchain. Enter with `nix develop`
  (or `direnv allow` if you add a `.envrc`).
- `CLAUDE.md` — this file.

Working tree only (gitignored, never committed):

- `engine/` — surfer's extracted Firefox source tree. Huge and expensive to
  rebuild from scratch.
- `node_modules/` — surfer + build tooling dependencies.

These two are the "cached build artifacts". They live in the main checkout
(`/Users/zotavka/Developer/zen-browser-desktop`, which stays on `zotavka/dev`)
and get copied into fresh feature worktrees to skip the slow first-build
steps.

## Building

The flake defines two shell functions, exported so they work under both
interactive `nix develop` and `nix develop --command bash -c '…'`:

- `zen-build` — full build. Handles first-time setup on its own (runs
  `npm ci` if `node_modules/.bin/surfer` is missing, `npm run init` if
  `engine/mozconfig` is missing), syncs en-US language packs into `engine/`,
  then `npm run build`. Use this after a fresh worktree, a surfer reset, or
  any change that touches native code.
- `zen-build-ui` — incremental rebuild for JS/chrome changes only. Syncs
  en-US packs and runs `npm run build:ui`. Much faster than `zen-build`; use
  it when iterating on the chrome UI.

After a build, launch with `npm start`.

The flake also prefers `$HOME/.mozbuild/clang/bin/clang` over nix's
clang-wrapper once `mach bootstrap` has fetched it — the wrapper mangles
preprocessing of `.S` files (notably `engine/config/external/icu/data/icu_data.S`
where `__APPLE__` stops firing). The override is guarded so a fresh
unbootstrapped checkout still enters the shell cleanly.

## Workflows

### Sync from upstream

```bash
cd /Users/zotavka/Developer/zen-browser-desktop    # already on zotavka/dev
git fetch upstream
git push origin upstream/dev:dev                   # origin/dev mirrors upstream/dev
git fetch origin
git rebase origin/dev                              # replay flake.nix/CLAUDE.md onto new upstream
# Resolve any conflicts (usually none — these files are unique to this branch).
git push --force-with-lease origin zotavka/dev
```

If the rebase breaks the engine/ cache (surfer bumped Firefox rev, for
example), delete it and let the next `zen-build` regenerate it:

```bash
trash engine node_modules
```

### Start a feature test branch

```bash
cd /Users/zotavka/Developer/zen-browser-desktop
git fetch origin
git worktree add \
  /Users/zotavka/Developer/Workspaces/zotavka-dev-gh-123-feature-zen-browser-desktop \
  -b zotavka/dev-gh-123-feature zotavka/dev

FEAT=/Users/zotavka/Developer/Workspaces/zotavka-dev-gh-123-feature-zen-browser-desktop

# Warm-start the build by cloning the cache from this repo. `cp -c` asks for
# APFS clonefile (O(1) on the same volume); it falls back to a real copy
# across volumes. `-a` preserves mtimes so surfer/mach incremental logic
# still works. Do NOT hardlink — that cross-contaminates build state.
cp -ac engine node_modules "$FEAT/"

cd "$FEAT"
nix develop
zen-build         # first full build in the feature tree
```

### Turn a tested feature into a clean PR branch

Once the feature works locally on `zotavka/dev-gh-123-feature`, cherry-pick
the code changes onto a branch off `origin/dev` (not `zotavka/dev`) so the PR
contains only upstream-relevant commits:

```bash
cd /Users/zotavka/Developer/zen-browser-desktop
git fetch origin
git worktree add \
  /Users/zotavka/Developer/Workspaces/gh-123-feature-zen-browser-desktop \
  -b gh-123-feature origin/dev

cd /Users/zotavka/Developer/Workspaces/gh-123-feature-zen-browser-desktop

# Cherry-pick only the commits that touch code the PR cares about.
# Skip any commit that only modifies flake.nix, flake.lock, or CLAUDE.md.
git log --oneline zotavka/dev..zotavka/dev-gh-123-feature
git cherry-pick <sha> <sha> ...

git push -u origin gh-123-feature
# Open the PR against upstream/dev.
```

## Invariants worth preserving

1. **Never include `flake.nix`, `flake.lock`, or this `CLAUDE.md` in a PR
   commit.** They belong only on `zotavka/dev` and its descendants. If a
   cherry-pick tries to drag them along, drop those hunks.
2. **Never commit `engine/` or `node_modules/`.** They are gitignored
   upstream; keep it that way. If `.gitignore` ever stops covering them, fix
   it in a PR to upstream rather than working around it here.
3. **Rebase, don't merge, when syncing from `origin/dev`.** Keeps this branch
   a linear delta on top of upstream, which makes "what's mine" legible and
   cherry-picks clean.
4. **`zotavka/dev`'s upstream is intentionally unset.** `git push` without an
   explicit remote/branch would otherwise push to `origin/dev` (because
   that's what `-b ... origin/dev` sets). Always push explicitly:
   `git push origin zotavka/dev` (and `--force-with-lease` after a rebase).

## Quick reference

| Task | Command |
|---|---|
| Enter dev shell | `nix develop` |
| Full build | `zen-build` |
| JS-only rebuild | `zen-build-ui` |
| Launch built browser | `npm start` |
| Sync upstream | `git fetch upstream && git push origin upstream/dev:dev` |
| Rebase this branch | `git fetch origin && git rebase origin/dev` |
| Warm build cache | `cp -ac engine node_modules <feat-worktree>/` |
| New feature worktree | See "Start a feature test branch" above |
| Promote to PR | See "Turn a tested feature into a clean PR branch" above |
