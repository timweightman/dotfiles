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
  gbw - Git branches wipe (merged/closed/gone)
  gww - Git worktrees wipe (merged/closed/gone)
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
    'gbw:Git branches wipe (merged/closed/gone)'
    'gww:Git worktrees wipe (merged/closed/gone)'
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

# prints "<branch>\t<reason>\t<worktreepath>" for local branches that are done:
# upstream is [gone], or its upstream is not its own remote branch and my PR for it is merged/closed with no open PR.
function tw_git_done_branches() {
  local -A open_prs done_prs
  local pr_list state number head line branch track worktree remote remoteref reason default_remote
  local -a fields remotes

  remotes=(${(f)"$(git remote)"})
  if (( ${remotes[(Ie)origin]} )); then
    default_remote=origin
  else
    default_remote=$remotes[1]
  fi

  if (( $+commands[gh] )) && pr_list=$(gh pr list --author @me --state all --limit 500 \
    --json number,state,headRefName --jq '.[] | [.state, (.number|tostring), .headRefName] | @tsv' 2>/dev/null); then
    # gh lists newest first, so the first merged/closed PR seen for a branch wins.
    while IFS=$'\t' read -r state number head; do
      [[ -z "$head" ]] && continue
      if [[ "$state" == OPEN ]]; then
        open_prs[$head]=$number
      elif [[ -z "${done_prs[$head]}" ]]; then
        done_prs[$head]="PR #$number ${(L)state}"
      fi
    done <<< "$pr_list"
  else
    echo "⚠️  gh unavailable, only checking branches with a gone upstream" >&2
  fi

  while IFS= read -r line; do
    fields=("${(@ps:\t:)line}")
    branch=$fields[1] track=$fields[2] worktree=$fields[3] remote=$fields[4] remoteref=$fields[5]
    [[ -z "$remote" || "$remote" == "." ]] && remote=$default_remote
    if [[ "$track" == "[gone]" ]]; then
      reason="remote branch gone"
    elif [[ "$remoteref" != "refs/heads/$branch" && -n "${done_prs[$branch]}" && -z "${open_prs[$branch]}" ]] \
      && ! git show-ref --quiet --verify "refs/remotes/$remote/$branch"; then
      reason=$done_prs[$branch]
    else
      continue
    fi
    print -r -- "$branch"$'\t'"$reason"$'\t'"$worktree"
  done < <(git for-each-ref \
    --format='%(refname:short)%09%(upstream:track)%09%(worktreepath)%09%(upstream:remotename)%09%(upstream:remoteref)' refs/heads)
}

function tw_git_main_worktree() {
  print -r -- "${$(git worktree list --porcelain | head -1)#worktree }"
}

# function to wipe local branches that are merged/closed or gone from the remote.
# Branches checked out in a worktree are left for gww.
function tw_git_branch_wipe() {
  echo "👀 Checking latest branches on remote..."
  quiet git fetch --prune

  local -a done_branches done_reasons
  local branch reason worktree skipped=0 i
  local main_worktree=$(tw_git_main_worktree)

  while IFS=$'\t' read -r branch reason worktree; do
    if [[ -n "$worktree" && "$worktree" == "$main_worktree" ]]; then
      echo "💡 $branch is done but checked out in the main worktree, switch branch and rerun tw gbw."
      continue
    elif [[ -n "$worktree" ]]; then
      (( ++skipped ))
      continue
    fi
    done_branches+=("$branch")
    done_reasons+=("$reason")
  done < <(tw_git_done_branches)

  if (( skipped > 0 )); then
    echo "💡 $skipped done branch(es) are checked out in worktrees, use tw gww for those."
  fi

  if [ ${#done_branches} -lt 1 ]; then
    echo "🌲 No merged/closed branches found."
    echo "👋 Bye!"
    return
  fi

  echo
  echo "🥀 Merged/closed branches:"
  for i in {1..${#done_branches}}; do
    echo "$done_branches[$i]  ($done_reasons[$i])"
  done
  echo
  echo "🚨 This will ${RED}forcibly wipe${DEF} the above branches."
  echo "   You could ${RED}lose work${DEF} done locally."
  echo

  if tw_confirm; then
    echo
    git branch -D "${done_branches[@]}"
    echo
    echo "👍 Done. Good luck!"
  else
    echo
    echo "❎ Cancelled."
  fi
}

# function to wipe worktrees whose branches are merged/closed or gone from the remote.
# (same idea as gbw, but also removes the worktree checkout)
function tw_git_worktree_wipe() {
  echo "👀 Checking latest branches on remote..."
  quiet git fetch --prune
  quiet git worktree prune

  local -a gone_paths gone_branches gone_reasons
  local branch reason worktree current_dir=${PWD:A} i
  local main_worktree=$(tw_git_main_worktree)

  while IFS=$'\t' read -r branch reason worktree; do
    [[ -z "$worktree" || "$worktree" == "$main_worktree" ]] && continue
    if [[ "$current_dir" == "$worktree" || "$current_dir" == "$worktree"/* ]]; then
      echo "⚠️  Skipping ${RED}$branch${DEF} as you are inside its worktree: $worktree"
      continue
    fi
    gone_paths+=("$worktree")
    gone_branches+=("$branch")
    gone_reasons+=("$reason")
  done < <(tw_git_done_branches)

  if [ ${#gone_paths} -lt 1 ]; then
    echo "🌲 No worktrees with merged/closed branches found."
    echo "👋 Bye!"
    return
  fi

  echo
  echo "🥀 Worktrees with merged/closed branches:"
  for i in {1..${#gone_paths}}; do
    echo "$gone_branches[$i]  →  $gone_paths[$i]  ($gone_reasons[$i])"
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
