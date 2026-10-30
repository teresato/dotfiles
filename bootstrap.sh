#!/usr/bin/env bash
# Takes a fresh Mac from nothing to a built nix-darwin config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Nix (official installer)"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  # --daemon gives the multi-user install (the only supported mode on macOS);
  # --yes makes it non-interactive. It will still prompt for sudo.
  curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install \
    | sh -s -- --daemon --yes
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: personalize the configured username"
# Do this before any sudo call: sudo resets $USER to root, so whoami has to
# run as the real interactive user first.
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the single \"user = \" line in flake.nix."
  echo "    Edit flake.nix yourself before continuing."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's \"user = \" line to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed -i '' -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Edit the single \"user = \" line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

echo "==> Step 4: first darwin-rebuild switch (pinned to nix-darwin-26.05)"
# darwin-rebuild doesn't exist yet on a fresh machine, so run it straight
# from the flake this once. After this, rebuild.sh works normally.
# This fetches the darwin-rebuild tool from the nix-darwin-26.05 release branch,
# not the exact flake.lock revision. The system config it applies is still pinned
# by this repo's flake.lock.
# sudo resets PATH to a secure default that excludes /nix/.../bin, so a
# freshly installed `nix` would not be found under sudo even though it's
# on PATH here. Resolve the absolute path first and invoke that instead.
NIX_BIN="$(command -v nix)"
# The official installer writes its own /etc/nix/nix.conf, and nix-darwin
# refuses to overwrite unrecognized files in /etc. Move it aside so nix-darwin
# can take over (nix.enable = true in flake.nix). On re-runs it is already
# nix-darwin's symlink, so this is skipped.
if [ -f /etc/nix/nix.conf ] && [ ! -L /etc/nix/nix.conf ]; then
  sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
fi
# The official installer doesn't enable flakes. Turn them on for this one run;
# afterwards nix-darwin's nix.settings.experimental-features covers it.
# "mac" is the flake host label - if you renamed it, change it in flake.nix
# and rebuild.sh too.
sudo "$NIX_BIN" --extra-experimental-features 'nix-command flakes' \
  run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake ~/.dotfiles#mac
# If this still fails with "nix: command not found", open a new terminal
# (the Nix installer adds nix to new shells' PATH) and re-run ./bootstrap.sh.
# If activation aborts over /etc/bashrc or /etc/zshrc, rename those by adding
# .before-nix-darwin to the end, then re-run ./bootstrap.sh.

echo "==> Done. Use ./rebuild.sh for future changes."
