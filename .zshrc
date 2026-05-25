export STARSHIP_CONFIG=~/dotfiles/.config/starship.toml

# Use Starship.rs prompt (brew install starship)
eval "$(starship init zsh)"

# History search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down
bindkey "^[OA" up-line-or-beginning-search # Up
bindkey "^[OB" down-line-or-beginning-search # Down

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

    ssh-reload)
      reload_ssh_keys
      ;;

    *)
      cat << EndOfMessage
Usage: tw <command>
Commands:
  dw - Docker wipe
  gbw - Git branches wipe
  ssh-reload - Reload SSH keys
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

# reload SSH keys
function reload_ssh_keys() {
  echo "Reloading SSH keys..."
  # A process named ssh-agent can exist while this shell has no (or a stale) SSH_AUTH_SOCK
  # (e.g. GUI terminals). Always ensure this session has a live socket before ssh-add.
  if [[ -z "$SSH_AUTH_SOCK" ]] || [[ ! -S "$SSH_AUTH_SOCK" ]]; then
    echo "Starting ssh-agent for this shell..."
    eval "$(ssh-agent -s)"
  fi
  find ~/.ssh -type f -name "id_*" ! -name "*.pub" | while read -r key; do
    ssh-add --apple-use-keychain "$key" 2>/dev/null && echo "Added key: $key"
  done
  echo "👍 SSH keys reloaded successfully."
}

# Run my own functions on shell startup, which often have console output
tw ssh-reload
