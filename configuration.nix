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
      "anomalyco/tap"  # opencode-v2
    ];
    # Only tools that aren't in nixpkgs (or are easier to run as a brew service).
    brews = [
      "herdr"
      "anomalyco/tap/opencode-v2"  # v2 isn't the opencode in nixpkgs yet
      "mole"                       # Mac cleaner; nixpkgs `mole` is a different tool
      "mysql"                      # run locally via `brew services`
    ];
    # GUI apps: casks either way.
    casks = [
      # terminals & editors
      "ghostty"
      "zed"
      "visual-studio-code"
      "intellij-idea"
      # ai
      "claude-code"
      "chatgpt"
      "codex"
      "conductor"
      # browsers & security
      "brave-browser"
      "burp-suite"
      "secretive"
      # productivity
      "obsidian"
      "raindropio"
      "superlist"
      "maccy"
      "tolaria"
      # utilities
      "appcleaner"
      "wallspace"
      # media & chat
      "spotify"
      "signal"
      # fonts
      "font-source-code-pro"
      "font-source-code-pro-for-powerline"
      "font-source-sans-3"
      "font-source-serif-4"
    ];
  };
}
