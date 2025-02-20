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


# enable extended glob patterns
setopt extendedglob


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

# custom shortcut functions for specific tasks
# tw <command>
function tw() {
  case "$1" in
    dw)
      tw_docker_wipe
      ;;

    gbw)
      tw_git_branch_wipe
      ;;

    *)
      cat << EndOfMessage
Usage: tw <command>
Commands:
  dw - Docker wipe
  gbw - Git branches wipe
EndOfMessage
  esac
}

# function to completely wipe Docker
function tw_docker_wipe() {
  if read -q "confirm?This will:
  • Stop all docker containers
  • Prune all containers, images, volumes and networks
  • Do a docker system prune including volumes
  • Shut down docker-compose, removing orphans and volumes
  Are you sure? (y/N) "; then
    echo
    echo "Stopping docker..."
    docker stop $(docker ps -aq)

    echo "Pruning containers..."
    docker container prune -f
    echo "Pruning images..."
    docker image prune -af
    echo "Pruning volumes..."
    docker volume prune -f
    echo "Pruning networks..."
    docker network prune -f
    echo "Pruning system including volumes..."
    docker system prune -af --volumes

    echo
    echo "Shutting down docker-compose, removing orphans and volumes..."
    docker-compose down --remove-orphans --volumes

    echo
    echo "Done – Good luck!"
  else
    echo
    echo "Cancelled."
  fi

}

# function to list git branches that were pushed, which are now *GONE* from the remote.
# *GENERALLY* these are my own merged+deleted branches)
function tw_git_branch_wipe() {
  branches=$(git branch -vv | grep ": gone]" | awk '{print $1}')
  echo
  echo $branches
  echo
  if read -q "confirm?This will forcibly wipe the above branches that no longer exist on the remote.

    There is a risk of losing work done locally.

  Are you sure? (y/N) "; then
    echo
    echo $branches | xargs git branch -D
    echo
    echo "Done - Good luck!"
  else
    echo
    echo "Cancelled."
  fi
}
