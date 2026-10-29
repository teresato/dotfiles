#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FLAKE="$DIR#mac"

# home.nix links configs through ~/.dotfiles, so it must point at this repo.
if [[ -e ~/.dotfiles && ! -L ~/.dotfiles ]]; then
  echo "~/.dotfiles exists and is not a symlink; move it aside first." >&2
  exit 1
fi
ln -sfn "$DIR" ~/.dotfiles

# A previous sudo run can leave flake.lock owned by root.
if [[ -e "$DIR/flake.lock" && ! -O "$DIR/flake.lock" ]]; then
  sudo env chown "$USER" "$DIR/flake.lock"
fi

# `sudo env` with full paths: sudo may block other targets, and secure_path omits Nix.
if [[ -x /run/current-system/sw/bin/darwin-rebuild ]]; then
  exec sudo env /run/current-system/sw/bin/darwin-rebuild switch --flake "$FLAKE"
else
  exec sudo env NIX_CONFIG="experimental-features = nix-command flakes" \
    /nix/var/nix/profiles/default/bin/nix run \
    github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake "$FLAKE"
fi
