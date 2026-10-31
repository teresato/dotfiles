{ pkgs, user, ... }:

{
  nix.enable = true;
  # Match the installed daemon (2.35.x) rather than downgrading to the default pkgs.nix (2.34).
  nix.package = pkgs.nixVersions.latest;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Keep the GitHub token out of the Nix store; `!include` silently skips the file if it's missing.
  nix.extraOptions = ''
    !include /etc/nix/github-token.conf
  '';

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  # fish as the login shell (zsh stays available as a fallback).
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Touch ID for sudo; written to /etc/pam.d/sudo_local, which survives macOS updates.
  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    # Uninstall (and remove data for) anything not listed below on each rebuild.
    onActivation.cleanup = "zap";
    taps = [
      "getsentry/xcodebuildmcp"  # xcodebuildmcp is tap-only
    ];
    # Only tools that aren't in nixpkgs (or are easier to run as a brew service).
    brews = [
      "herdr"
      "opencode"                   # brew core has v2; nixpkgs 26.05-darwin is still on v1
      "mole"                       # Mac cleaner; nixpkgs `mole` is a different tool
      "mysql"                      # run locally via `brew services`
      "cliclick"                   # not packaged in nixpkgs
      "getsentry/xcodebuildmcp/xcodebuildmcp"
    ];
    # GUI apps: casks either way. One flat alphabetical list -- every cask
    # installed on this machine is declared here, so cleanup is safe to enable.
    casks = [
      "1password"
      "balenaetcher"
      "brainfm"
      "brave-browser"
      "burp-suite"
      "chatgpt"
      "claude-code"
      "cmux"
      "codex"
      "codex-app"
      "conductor"
      "discord"
      "fixkey"
      "font-source-code-pro"
      "font-source-code-pro-for-powerline"
      "ghostty"
      "loom"
      "maccy"
      "obsidian"
      "orion"
      "puremac"
      "raindropio"
      "rancher"
      "raycast"
      "rectangle"
      "secretive"
      "signal"
      "slack"
      "spotify"
      "superlist"
      "tolaria"
      "visual-studio-code"
      "wallspace"
      "whatsapp"
      "yubico-authenticator"
      "yubico-yubikey-manager"
      "zed"
      "zoom"
    ];
  };
}
