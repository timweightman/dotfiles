# Install PowerLevel10k from here:
# https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#installation

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source ~/.config/zsh/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# engage ZSH autocompletion
autoload -Uz compinit && compinit


# case-insensitive autocompletion matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'


# arrow key autocompletion navigation
zstyle ':completion:*' menu yes select


# up line or beginning search history backward with up arrow key
autoload -Uz up-line-or-beginning-search
zle -N up-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
# In theory the below should work to look up key code, but for some reason
# it produces key code "^[OB", and doesn't work
# bindkey "${key[Up]}" down-line-or-beginning-search


# down line or beginning search history forward with down arrow key
autoload -Uz down-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
# In theory the below should work to look up key code, but for some reason
# it produces key code "^[OB", and doesn't work
# bindkey "${key[Down]}" down-line-or-beginning-search
