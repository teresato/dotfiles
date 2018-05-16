##### PATH Export #####
export GOPATH=$HOME/workspace/golang
export PATH=/usr/local/go/bin:$GOPATH/bin
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# Path to dotfiles installation
# export DOTFILES=$HOME/.dotfiles

# Path to your oh-my-zsh installation.
export ZSH=/Users/teresato/.oh-my-zsh

ZSH_THEME="agnoster"

# Activate Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=$DOTFILES

plugins=(git zsh-syntax-highlighting golang)

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

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
alias sz="source ~/.zshrc"
alias cppath="pwd | pbcopy"
alias cpssh="pbcopy < $HOME/.ssh/id_rsa.pub"
alias reload="exec $SHELL"
alias sz="source $HOME/.zshrc"
alias l="exa -abghl --git --color=always --group-directories-first"
alias tree="exa -T"
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
alias weather="curl -4 http://wttr.in"
alias shrug="echo '¯\_(ツ)_/¯' | pbcopy"
alias ip="curl http://checkip.amazonaws.com"

# Vagrant
alias v="vagrant global-status"
alias vup="vagrant up"
alias vhalt="vagrant halt"
alias vssh="vagrant ssh"
alias vreload="vagrant reload"
alias vrebuild="vagrant destroy --force && vagrant up"

# Docker
alias dstop="docker stop $(docker ps -a -q)"
alias dpurgecontainers="dstop && docker rm $(docker ps -a -q)"
alias dpurgeimages="docker rmi $(docker images -q)"
dbuild() { docker build -t=$1 .; }
dbash() { docker exec -it $(docker ps -aqf "name=$1") bash; }

# Git
alias g='git'
alias gs='git status -sb'
alias gf='git fetch'
alias gc='git commit'
alias gb='git branch'
alias gbl='git branch -vv -a'
alias gco='git checkout'
alias gsm='git submodule'
alias gd='git diff'
alias gdt='git difftool'
alias gds='git diff --staged'
alias gl='git log \
	--graph \
	--abbrev-commit \
	--decorate \
	--format=format:"%C(yellow)%h%C(reset) %C(white)%s%C(reset) %C(blue)<%an>%C(reset)%C(bold yellow)%d%C(reset) %C(black)%ar%C(reset)" \
	--all'
alias glt='git log \
	--graph \
	--abbrev-commit \
	--decorate \
	--format=format:"%C(bold black)%ad%C(reset) %C(yellow)%h%C(reset) %C(white)%s%C(reset) %C(blue)<%an>%C(reset)%C(bold yellow)%d%C(reset) %C(black)%ar%C(reset)" \
	--date=format:"%Y-%m-%d %H:%M" \
	--all'
function ga() { git add "$@" && git status -sb }

# Ban npm if project uses Yarn
npm() {
	if [ -f "yarn.lock" ]; then
		echo "$(tput sgr 0 1)$(tput setaf 1)You should use Yarn for this project.$(tput sgr0)"
		return
	fi
	command npm $@
}

# Functions
# Get colors in manual pages
function man() {
	env \
		LESS_TERMCAP_mb="$(printf '\e[1;31m')" \
		LESS_TERMCAP_md="$(printf '\e[1;31m')" \
		LESS_TERMCAP_me="$(printf '\e[0m')" \
		LESS_TERMCAP_se="$(printf '\e[0m')" \
		LESS_TERMCAP_so="$(printf '\e[1;44;33m')" \
		LESS_TERMCAP_ue="$(printf '\e[0m')" \
		LESS_TERMCAP_us="$(printf '\e[1;32m')" \
		man "$@"
}

function note() {
  echo `date` >> ~/.notes
  echo "$1 \n" >> ~/.notes
}

function calc() {
	# local result=""
	result="$(printf "scale=10;%s\\n" "$*" | bc --mathlib | tr -d '\\\n')"
	#						└─ default (when `--mathlib` is used) is 20

	if [[ "$result" == *.* ]]; then
		printf "%s" "$result" |
			sed -e 's/^\./0./'  \
			-e 's/^-\./-0./' \
			-e 's/0*$//;s/\.$//'
	else
		printf "%s" "$result"
	fi
	printf "\\n"
}




