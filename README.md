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
1. If you have multiple GitHub profiles (separate for work, personal...), then it is easier to keep this repo under you personal profile, and invite your work profile as a collaborator on the repo, to be able to clone and push updates more easily without the extra folder and SSH configuration.
1. HOWEVER, if you really need to specify your work and personal things separately email address, be sure to uncomment the relevant sections in `~/dotfiles/.gitconfig` and update them to match the correct GitHub email, folder, etc.

    You will also need to check / update the `~/dotfiles/.ssh/config` as well to make use of the correct SSH key(s).

    This might include commenting or uncommenting the `[core]` and `[url ...]` sections of one or both of `.gitconfig-personal` or `.gitconfig-work` as appropriate.

    You'll have to think it over and work that part out yourself case-by-case depending if you're using the same or separate SSH key(s), GitHub account email(s), etc.


## How I set this repo up

The original basis for this repo came from [this guide](https://www.atlassian.com/git/tutorials/dotfiles) with a few notable exceptions:
- I changed `$HOME/.cfg` to `$HOME/Work/dotfiles`
- I renamed the command from `config` to `dotfiles`

My reason for changing the folder path, was:
- I wanted to store this `dotfiles` repository in my _work_ GitHub profile\
    &rarr; and to do that, I needed it to use my _work_ GitHub SSH key\
    &emsp;&rarr; and to do that, I needed to have the `dotfiles` git folder tracked under the `Work` folder on my laptop\
    &emsp;&emsp;&rarr; because my ~/.ssh/config and ~/.gitconfig_work depend on that `Work` folder path to function seamlessly

<!--
> These steps are a bit out of date, and personally I think they need some refinement. \
> I would rather see a small shell script written to do these things automatically.

## Steps for using this repository if you are not *me* (Tim Weightman)

1. In .ssh/config https://github.com/timweightman/dotfiles/blob/master/.ssh/config
    - Update [line 4](https://github.com/timweightman/dotfiles/blob/master/.ssh/config#L4) with your work SSH key file path
    - Update [line 10](https://github.com/timweightman/dotfiles/blob/master/.ssh/config#L10) with your personal SSH key file path

1. In .gitconfig https://github.com/timweightman/dotfiles/blob/master/.gitconfig
    - Make sure you are happy with the work and personal folder paths, I have used ~/Work and ~/Personal respectively

1. In .gitconfig-personal https://github.com/timweightman/dotfiles/blob/master/.gitconfig-personal
    - Update [lines 2 and 3](https://github.com/timweightman/dotfiles/blob/master/.gitconfig-personal#L2-L3) with your personal github email and user name
    - Update [line 5](https://github.com/timweightman/dotfiles/blob/master/.gitconfig-personal#L5) with the correct file path for your personal github SSH key file

1. In .gitconfig-work https://github.com/timweightman/dotfiles/blob/master/.gitconfig-work
    - Update [lines 2 and 3](https://github.com/timweightman/dotfiles/blob/master/.gitconfig-work#L2-L3) with your work github email and user name
    - Update [line 5](https://github.com/timweightman/dotfiles/blob/master/.gitconfig-work#L5) with the correct file path for your work github SSH key file
    - Update [lines 12 and 13](https://github.com/timweightman/dotfiles/blob/master/.gitconfig-work#L12-L13) with your work github user name

1. In .zshrc https://github.com/timweightman/dotfiles/blob/master/.zshrc
    - Update [.zshrc](https://github.com/timweightman/dotfiles/blob/master/.zshrc) on the lines that do `ssh-add` (just search `ssh-add` in the `.zshrc` file), with the correct file paths for your work and personal SSH key files so they are automatically added to the SSH agent whenever you restart your machine / open a terminal -->
