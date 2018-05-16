#!/bin/bash

dotfiles=("${HOME}/.vimrc" "${HOME}/.zshrc")
dir="${HOME}/.dotfiles"

for dotfile in "${dotfiles[@]}";do
 ln -sf "${HOME}/${dotfile}" "${dir}"
done