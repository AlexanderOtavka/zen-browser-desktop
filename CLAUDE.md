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

These two are the "cached build artifacts" — they stay on disk in this
worktree and get copied into fresh feature worktrees to skip the slow first-
build steps.

## Workflows

### Sync from upstream

```bash
# From anywhere in the repo
git fetch upstream
git -C /Users/zotavka/Developer/zen-browser-desktop push origin upstream/dev:dev
# origin/dev now mirrors upstream/dev.

# In this worktree
git fetch origin
git rebase origin/dev            # replay flake.nix + CLAUDE.md onto new upstream
# Resolve any conflicts (usually none — these files are unique to this branch).
git push --force-with-lease origin zotavka/dev
```

If the rebase breaks the engine/ cache (surfer bumped Firefox rev, for
example), delete it and let the next build rebuild from scratch:

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
SRC=/Users/zotavka/Developer/Workspaces/zotavka-dev-zen-browser-desktop

# Warm-start the build by reusing the cache. Use `cp -a` (preserves mtimes so
# surfer/mach incremental logic still works). A hardlink clone would be
# faster but risks cross-contaminating the two worktrees' build state.
cp -a "$SRC/engine" "$SRC/node_modules" "$FEAT/"

cd "$FEAT"
nix develop      # or direnv
# ...hack, build, test...
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
| Sync upstream | `git fetch upstream && git push origin upstream/dev:dev` |
| Rebase this branch | `git fetch origin && git rebase origin/dev` |
| New feature worktree | See "Start a feature test branch" above |
| Warm build cache | `cp -a …/zotavka-dev-…/engine …/zotavka-dev-…/node_modules <feat>/` |
| Promote to PR | See "Turn a tested feature into a clean PR branch" above |
