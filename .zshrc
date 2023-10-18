##### PATH Export #####
export GOPATH=$HOME/Developer/golang
export PATH=/usr/local/go/bin:$GOPATH/bin
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# Path to dotfiles installation
# export DOTFILES=$HOME/.dotfiles

# Path to your oh-my-zsh installation.
export ZSH=/Users/teresato/.oh-my-zsh

# ZSH_THEME="agnoster"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Activate Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=$DOTFILES

plugins=(
    1password
    git
    kubectl
    terraform
    zsh-autosuggestions
    zsh-syntax-highlighting
    golang
)

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LC_ALL=en_GB.UTF-8
export LANG=en_GB.UTF-8

# Preferred editor for local and remote sessions
export EDITOR='vim'

# Pyenv 
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# GCP
export GCLOUD=/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk
source $GCLOUD/path.zsh.inc
source $GCLOUD/completion.zsh.inc

#Shortcuts
alias lock='/System/Library/CoreServices/"Menu Extras"/User.menu/Contents/Resources/CGSession -suspend'
alias c="clear"
alias reload="exec $SHELL"
alias ez="vi ~/.zshrc"
alias cppath="pwd | pbcopy"
alias cpssh="pbcopy < $HOME/.ssh/id_rsa.pub"
alias reload="exec $SHELL"
alias sz="source $HOME/.zshrc"
# alias l="exa -abghl --git --color=always --group-directories-first"
# alias tree="exa -T"
alias jq="jq -C"
alias less="less -r"
alias cp="cp -iv"
alias rm="rm -iv"
alias mv="mv -iv"
alias ls="ls -FGh"
alias du="du -cksh"
alias df="df -h"
alias gsed="sed"
alias rgrep="grep -r"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias ip="curl http://checkip.amazonaws.com"

gdub() {
    git fetch --all --prune;
    for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}');
    do
        git branch -D $branch;
    done;
}

eval "$(zoxide init zsh)"

