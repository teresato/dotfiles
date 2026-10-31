# dotfiles

nix-darwin + Home Manager configuration for macOS (Apple Silicon).

## Layout

| Path | What |
|------|------|
| `flake.nix` | Inputs (nixpkgs 26.05, nix-darwin, home-manager, nix-homebrew) and the `mac` system |
| `configuration.nix` | System config: Nix settings, macOS defaults, Homebrew (casks/brews) |
| `home.nix` | Home Manager: packages, shells, starship, mise, and config symlinks |
| `home/` | Real config files, symlinked into `~` via `mkOutOfStoreSymlink` (edit-in-place) |
| `bootstrap.sh` | One-time setup that takes a fresh Mac to a built config |
| `rebuild.sh` | Convenience wrapper around the switch command |

## Rebuild

```sh
sudo env /run/current-system/sw/bin/darwin-rebuild switch --flake ~/.dotfiles#mac
```

`~/.dotfiles` is a symlink to this repo. `sudo env` is used because `sudo` may
block the plain `darwin-rebuild` path.

## Tooling split

- **Nix** manages CLI tools, GUI casks (via Homebrew), and dotfile symlinks.
- **mise** manages per-project language versions (terraform, node, python, ...)
  from `.mise.toml` / `.tool-versions`. Global fallbacks live in `home.nix`
  (`programs.mise.globalConfig`). Avoid `"latest"` there — it makes mise hit
  GitHub's API on every shell prompt.
- **Homebrew** `cleanup = "zap"` is on: anything not listed in `configuration.nix`
  gets uninstalled on rebuild, and a removed cask's app data goes with it. Add new
  apps to the config, not just `brew install`.

## Commits and PRs

Commits and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

- **All repos:** `home/.config/git/hooks/commit-msg` rejects non-conforming
  messages through a global `core.hooksPath`. Every hook there also runs the
  repo's own `.git/hooks` equivalent. Repos that set their own `core.hooksPath`
  (such as husky) skip the global hook.
- **Agents:** `home/AGENTS.md` and the `conventional-commits` Claude Code skill
  in `home/.claude/skills` carry the rules.
- **This repo:** `.github/workflows/conventional-commits.yml` checks PR titles
  and commits. Other repos need their own copy, plus `_check-message`.

## Secrets

Secrets are **not** in this repo. They live in `~/.secrets.env` (mode 600,
sourced at shell startup, blocked by the global gitignore as `*.secrets.env`).

### GitHub tokens — which goes where

| Consumer | Token | Source |
|----------|-------|--------|
| mise (`MISE_GITHUB_TOKEN`) | `gh auth token` (`gho_` OAuth) | github.com directly, OAuth token is fine |
| Nix flake fetches | `/etc/nix/github-token.conf` | `echo "access-tokens = github.com=$(gh auth token)" \| sudo tee /etc/nix/github-token.conf` |

`gh` is the source of truth for both.

## First-time / new-machine setup

1. Clone this repo and run `./bootstrap.sh` once from it. The script:
   - installs Nix if it's missing
   - symlinks the repo to `~/.dotfiles`
   - checks the `user` in `flake.nix` against the current user, offering to
     rewrite it if they differ
   - moves the installer's `/etc/nix/nix.conf` aside
   - runs the first `darwin-rebuild switch`
2. Create `~/.secrets.env` (see above) and set up pinentry/GPG as needed.
3. Subsequent rebuilds use `./rebuild.sh` or the command in [Rebuild](#rebuild).

If the script reports `nix: command not found`, open a new terminal and re-run
it. If activation aborts over `/etc/bashrc` or `/etc/zshrc`, add
`.before-nix-darwin` to the end of those filenames and re-run it.
