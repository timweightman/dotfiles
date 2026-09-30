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

# Autocompletion
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zmodload zsh/complist

function tw_init() {
  echo "Setting up dotfiles references..."

  # Setup ~/.zshrc
  if [ ! -f ~/.zshrc ] || ! grep -q "source ~/dotfiles/.zshrc" ~/.zshrc; then
    # Ensure file ends with a newline before appending to avoid corrupting the last line
    [ -f ~/.zshrc ] && [ -n "$(tail -c 1 ~/.zshrc 2>/dev/null)" ] && echo "" >> ~/.zshrc
    echo "source ~/dotfiles/.zshrc" >> ~/.zshrc
    echo "Added dotfiles reference to ~/.zshrc"
  fi

  echo "Checking for Homebrew..."
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Make brew available in the current session
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    echo "Homebrew is already installed."
  fi
}

# custom shortcut functions for specific tasks
# tw <command>
function tw() {
  case "$1" in
    init)
      tw_init
      ;;

    dw)
      tw_docker_wipe
      ;;

    gbw)
      tw_git_branch_wipe
      ;;

    gww)
      tw_git_worktree_wipe
      ;;

    ssh-reload)
      reload_ssh_keys
      ;;

    kill)
      tw_kill_port "$2"
      ;;
    *)
      cat << EndOfMessage
Usage: tw <command>
Commands:
  init - Initialize dev environment (installs helix)
  dw - Docker wipe
  gbw - Git branches wipe
  gww - Git worktrees wipe
  ssh-reload - Reload SSH keys
  kill <port> - Kill process listening on a specific port
EndOfMessage
  esac
}

# Autocompletion for tw function
function _tw() {
  local -a commands
  commands=(
    'init:Initialize dev environment (installs helix)'
    'dw:Docker wipe'
    'gbw:Git branches wipe'
    'gww:Git worktrees wipe'
    'ssh-reload:Reload SSH keys'
    'kill:Kill process listening on a specific port'
  )
  _describe -t commands 'tw commands' commands
}
compdef _tw tw

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

# function to list git worktrees whose branches were pushed, but are now *GONE* from the remote.
# (same idea as gbw, but also removes the worktree checkout)
function tw_git_worktree_wipe() {
  echo "👀 Checking latest branches on remote..."
  quiet git fetch --prune
  quiet git worktree prune

  local -a gone_paths gone_branches
  local line entry_path entry_branch current_dir=${PWD:A} is_main_entry=true i

  # Each porcelain entry ends with a blank line; the extra echo makes sure the last entry is flushed.
  while IFS= read -r line; do
    case "$line" in
      "worktree "*)
        entry_path=${line#worktree }
        ;;
      "branch refs/heads/"*)
        entry_branch=${line#branch refs/heads/}
        ;;
      "")
        if [[ -n "$entry_path" ]] && ! $is_main_entry && [[ -n "$entry_branch" ]] \
          && [[ "$(git for-each-ref --format='%(upstream:track)' "refs/heads/$entry_branch")" == "[gone]" ]]; then
          if [[ "$current_dir" == "$entry_path" || "$current_dir" == "$entry_path"/* ]]; then
            echo "⚠️  Skipping ${RED}$entry_branch${DEF} as you are inside its worktree: $entry_path"
          else
            gone_paths+=("$entry_path")
            gone_branches+=("$entry_branch")
          fi
        fi
        [[ -n "$entry_path" ]] && is_main_entry=false
        entry_path=
        entry_branch=
        ;;
    esac
  done < <(git worktree list --porcelain; echo)

  if [ ${#gone_paths} -lt 1 ]; then
    echo "🌲 No worktrees with branches gone from the remote."
    echo "👋 Bye!"
    return
  fi

  echo
  echo "🥀 Worktrees with branches gone from the remote:"
  for i in {1..${#gone_paths}}; do
    echo "$gone_branches[$i]  →  $gone_paths[$i]"
  done
  echo
  echo "🚨 This will ${RED}forcibly remove${DEF} the above worktrees, ${RED}including uncommitted and untracked files${DEF},"
  echo "   and ${RED}delete${DEF} their local branches. You could ${RED}lose work${DEF} done locally."
  echo

  if tw_confirm; then
    echo
    for i in {1..${#gone_paths}}; do
      if git worktree remove --force "$gone_paths[$i]"; then
        git branch -D "$gone_branches[$i]"
      else
        echo "💥 Could not remove worktree $gone_paths[$i], so keeping branch ${RED}$gone_branches[$i]${DEF}."
      fi
    done
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

# function to kill a process on a specific port
function tw_kill_port() {
  local port=$1
  if [[ -z "$port" ]]; then
    echo "🚨 Please provide a port number. Usage: tw kill <port>"
    return 1
  fi

  echo "🔍 Looking for process on port $port..."
  local pids=$(lsof -t -nP -i :$port)

  if [[ -z "$pids" ]]; then
    echo "👍 No process found on port $port."
    return 0
  fi

  local pids_flat=$(echo $pids | tr '\n' ' ')
  echo "💀 Killing process(es) on port $port (PIDs: $pids_flat)"
  echo $pids | xargs kill -9 2>/dev/null
  echo "✅ Done."
}

# Run my own functions on shell startup, which often have console output
tw ssh-reload
