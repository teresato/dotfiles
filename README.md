# dotfiles

nix-darwin + Home Manager configuration for macOS (Apple Silicon).

## Layout

| Path | What |
|------|------|
| `flake.nix` | Inputs (nixpkgs 26.05, nix-darwin, home-manager, nix-homebrew) and the `mac` system |
| `configuration.nix` | System config: Nix settings, macOS defaults, Homebrew (casks/brews) |
| `home.nix` | Home Manager: packages, zsh, starship, mise, and config symlinks |
| `home/` | Real config files, symlinked into `~` via `mkOutOfStoreSymlink` (edit-in-place) |
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

## Secrets

Secrets are **not** in this repo. They live in `~/.secrets.env` (mode 600,
sourced by zsh, blocked by the global gitignore as `*.secrets.env`).

### GitHub tokens — which goes where

| Consumer | Token | Source |
|----------|-------|--------|
| mise (`MISE_GITHUB_TOKEN`) | `gh auth token` (`gho_` OAuth) | github.com directly, OAuth token is fine |
| Nix flake fetches | `/etc/nix/github-token.conf` | `echo "access-tokens = github.com=$(gh auth token)" \| sudo tee /etc/nix/github-token.conf` |

`gh` is the source of truth for both.

## First-time / new-machine setup

1. Move the installer's nix.conf aside: `sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin`
2. Bootstrap once with `nix run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/.dotfiles#mac`
3. Create `~/.secrets.env` (see above) and set up pinentry/GPG as needed.
4. Subsequent rebuilds use the command in [Rebuild](#rebuild).
