# dotfiles
This repo covers my very minimal setup for ZSH and a couple of other config/dotfile things.

## General idea
1. Clone this repo to your user root (`~/dotfiles` or `$HOME/dotfiles`)
1. Create a `.zshrc` in your user root, and add:
    ```
    source ~/dotfiles/.zshrc
    ```
1. Create a `.gitconfig`, and add
    ```
    [include]
        path = ~/dotfiles/.gitconfig
    ```
1. **GitHub SSH (two Host entries, no secrets in this repo)**  
   - `~/.ssh/config` in this repo defines **`Host github.com`** (personal key) and **`Host github.com-work`** → same `HostName github.com` (work key). Identity is chosen by which host appears in the remote URL.  
   - **`Host github.com-work`** uses **`IdentitiesOnly yes`** so only the work key is offered there. **`Host github.com`** omits **`IdentitiesOnly`** so ssh can fall back to **`ssh-agent`** keys after the configured `IdentityFile` (useful when the key GitHub accepts is loaded in the agent, or you use multiple keys).  
   - Install on a machine: either **`ln -sf ~/dotfiles/.ssh/config ~/.ssh/config`**, or keep your own `~/.ssh/config` and add **`Include ~/dotfiles/.ssh/config`** (or `Include` the path where you cloned this repo).  
   - Place **private** keys only under `~/.ssh/` on that machine (filenames can match `IdentityFile` lines or edit those lines to match your local names). Nothing secret is copied into `~/dotfiles/`.
1. **Git identities by folder** come from `~/dotfiles/.gitconfig` **`includeIf`** rules plus **`~/.gitconfig-personal`** / **`~/.gitconfig-work`**: user name, email, and (for work) `url ... insteadOf` so `git@github.com` remotes become `git@github.com-work` for repos under your home directory except paths matched earlier. Edit emails, org segments in `url` rules, and `includeIf` paths if your layout differs.
1. If you have multiple GitHub profiles, you can keep this repo under one GitHub account and add the other as a collaborator, or use separate remotes; the SSH Host split above still applies.

### Optional (macOS OpenSSH from Apple)

If your system `ssh` supports it, you can add **`UseKeychain yes`** under each `Host` block in a **local-only** `~/.ssh/config` fragment (do not commit keychain-related or machine-specific paths into `~/dotfiles` if you want the repo shareable as-is). Many setups rely on `ssh-add --apple-use-keychain` from the shell instead.


## How I set this repo up

The original basis for this repo came from [this guide](https://www.atlassian.com/git/tutorials/dotfiles) with a few notable exceptions:
- I changed `$HOME/.cfg` to `$HOME/dotfiles` (path is arbitrary; see **`includeIf`** in `.gitconfig` and **General idea** for SSH/Git layout).
- I renamed the command from `config` to `dotfiles`

Historically I tied clone location to work vs personal tooling; today **GitHub auth** is driven by **`Host github.com` / `Host github.com-work`** in **`.ssh/config`** plus work **`url ... insteadOf`** in **`.gitconfig-work`**, and **commit identity** by **`includeIf gitdir:`** in **`.gitconfig`**. On a new laptop, **`Include`** that SSH file from **`~/.ssh/config`**, install keys only under **`~/.ssh/`**, and adjust **`IdentityFile`** names and **`includeIf`** paths as needed.
