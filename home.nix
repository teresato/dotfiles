{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli tools
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    bat       # cat with syntax highlighting
    glow      # markdown in the terminal
    atuin     # shell history
    gh        # github cli
    fish
    pi-coding-agent  # `pi`
    gnupg
    pinentry_mac
    git
    zoxide    # `z` -- jump to recent dirs
    duf       # friendlier df
    curl      # newer than the macOS build
    findutils # GNU find/xargs, not the BSD ones
    # languages & build (versions still pinned per-project by mise)
    go
    uv        # python package/venv manager
    pnpm
    # cloud & infra
    awscli2
    kubectl
    kubernetes-helm  # `helm`
    minikube
    docker-client    # CLI only; colima provides the daemon
    colima
    terraform-docs
    ollama
    # media & ocr
    ffmpeg
    tesseract
    # security
    openssh   # newer than the macOS build
    yubikey-manager  # `ykman`
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  # gpg-agent needs an explicit pinentry now that the brew one is gone.
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
    default-cache-ttl 600
    max-cache-ttl 7200
  '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    envExtra = ''
      export PATH="$HOME/.local/bin:$PATH"  # uv
    '';
    initContent = ''
      bindkey '^f' autosuggest-accept

      export GPG_TTY=$(tty)
      gpgconf --launch gpg-agent

      # Secrets (API tokens, etc.) live outside the repo; this file is gitignored.
      [[ -f ~/.secrets.env ]] && source ~/.secrets.env

      export PNPM_HOME="$HOME/Library/pnpm"
      case ":$PATH:" in
        *":$PNPM_HOME/bin:"*) ;;
        *) export PATH="$PNPM_HOME/bin:$PATH" ;;
      esac

      # Delete local branches whose remote is gone.
      prune() {
        git fetch --all --prune
        for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}'); do
          git branch -D "$branch"
        done
      }
      alias gdub=prune
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      gst = "git status";
      tf = "terraform";
      k = "kubectl";
      npm = "pnpm";
      npx = "pnpm dlx";
      tree = "eza --tree";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.fish = {
    enable = true;
    # foreign-env lets fish source the bash-style ~/.secrets.env (incl. $(gh auth token)).
    plugins = [
      { name = "foreign-env"; src = pkgs.fishPlugins.foreign-env.src; }
    ];
    # Abbreviations expand as you type, so history stores the real command.
    shellAbbrs = {
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      gst = "git status";
      tf = "terraform";
      k = "kubectl";
      npm = "pnpm";
      npx = "pnpm dlx";
      tree = "eza --tree";
    };
    # Kept as aliases: not command-word shortcuts, or they wrap a function.
    shellAliases = {
      ".." = "cd ..";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
      gdub = "prune";
    };
    shellInit = ''
      set -gx PNPM_HOME "$HOME/Library/pnpm"
      fish_add_path $HOME/.local/bin
      fish_add_path $PNPM_HOME/bin

      # Secrets live outside the repo; load the bash-style file via foreign-env.
      test -f ~/.secrets.env; and fenv source ~/.secrets.env
    '';
    interactiveShellInit = ''
      set -gx GPG_TTY (tty)
      gpgconf --launch gpg-agent

      bind \cf accept-autosuggestion

      # Delete local branches whose remote is gone.
      function prune
        git fetch --all --prune
        for branch in (git branch -vv | grep ': gone]' | awk '{print $1}')
          git branch -D $branch
        end
      end
    '';
  };

  # Also aliases ls to eza in every shell.
  programs.eza.enable = true;

  # Shell init only; the Catppuccin Powerline preset is symlinked below (edit-in-place).
  programs.starship.enable = true;

  # Per-project language versions (terraform, python, node, ...) via .mise.toml / .tool-versions.
  # Replaces pyenv and tfenv; the shell hook activates the right version on cd.
  programs.mise = {
    enable = true;
    # Global fallbacks when a project doesn't pin a version.
    # Avoid "latest" here: it makes mise hit GitHub's API on every prompt.
    # terraform is pinned per-project, so it's intentionally omitted.
    globalConfig.tools = {
      node = "24";
      python = "3.12";
    };
  };

  # vi and vim both open neovim.
  home.file.".local/bin/vi".source = "${pkgs.neovim}/bin/nvim";
  home.file.".local/bin/vim".source = "${pkgs.neovim}/bin/nvim";

  # colima only provides the daemon, so the docker CLI plugins come from nix.
  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/bin/docker-compose";
  home.file.".docker/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/bin/docker-buildx";

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".config/ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/ghostty/config";
  home.file.".config/ghostty/shaders".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/ghostty/shaders";
  home.file.".config/starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/starship.toml";
  home.file.".config/bat/config".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/bat/config";
  home.file.".config/atuin/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/atuin/config.toml";
  home.file.".config/zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/zed/settings.json";
  home.file.".config/gh/config.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/gh/config.yml";
  home.file.".config/git/ignore".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/git/ignore";
  home.file.".config/git/config".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/git/config";
  home.file.".config/git/commit-template".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/git/commit-template";
  home.file.".config/git/hooks".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/git/hooks";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skills";
  home.file.".claude/claude-statusline".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/claude-statusline";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/opencode.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/opencode.jsonc";
}
