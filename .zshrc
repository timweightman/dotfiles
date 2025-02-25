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


# engage prompt command for colourizing text
autoload colors; colors


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

RED=$fg[red]
DEF=$reset_color

function quiet() {
  $@ >/dev/null
}

function tw_confirm() {
  if read -q "confirm?${RED}Are you sure? (y/N)${DEF} "; then
    true
  else
    # echo here to nudge an end of line so echo's outside this function will behave as I expect
    # I'm not sure why, but the `true` case above already seems to complete its line.
    echo
    false
  fi
}

# function to completely wipe Docker
function tw_docker_wipe() {
  echo "🚨 This will:"
  echo "   • Stop all docker containers"
  echo "   • Prune all ${RED}containers, images, volumes and networks${DEF}"
  echo "   • Do a ${RED}docker system prune${DEF} including ${RED}volumes${DEF}"
  echo "   • Shut down ${RED}docker-compose${DEF}, removing ${RED}orphans and volumes${DEF}"
  echo

  if tw_confirm; then
    echo
    echo "✋ Stopping docker..."
    docker stop $(docker ps -aq)

    echo "📦 Pruning containers..."
    docker container prune -f
    echo "🖼️ Pruning images..."
    docker image prune -af
    echo "💾 Pruning volumes..."
    docker volume prune -f
    echo "🔌 Pruning networks..."
    docker network prune -f
    echo "🖥️ Pruning system including volumes..."
    docker system prune -af --volumes

    echo
    echo "🎼 Shutting down docker-compose, removing orphans and volumes..."
    docker-compose down --remove-orphans --volumes

    echo
    echo "👍 Done. Good luck!"
  else
    echo
    echo "❎ Cancelled."
  fi
}

# function to list git branches that were pushed, which are now *GONE* from the remote.
# *GENERALLY* these are my own merged+deleted branches)
function tw_git_branch_wipe() {
  echo "👀 Checking latest branches on remote..."
  quiet git fetch

  branches=$(git branch -vv | grep ": gone]" | awk '{print $1}')

  if [ ${#branches} -lt 1 ]; then
    echo "🌲 No branches gone from the remote."
    echo "👋 Bye!"
    return
  fi

  echo
  echo "🥀 Branches gone from the remote:"
  echo $branches
  echo
  echo "🚨 This will ${RED}forcibly wipe${DEF} the above branches that no longer exist on the remote."
  echo "   You could ${RED}lose work${DEF} done locally."
  echo

  if tw_confirm; then
    echo
    echo $branches | xargs git branch -D
    echo
    echo "👍 Done. Good luck!"
  else
    echo
    echo "❎ Cancelled."
  fi
}
