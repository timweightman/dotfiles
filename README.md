# dotfiles
Including ZSH (oh-my-zsh), Git config (personal and work), SSH config (personal and work)

## How I set this repo up

I followed [this guide](https://www.atlassian.com/git/tutorials/dotfiles) with a few notable exceptions:
- I changed `$HOME/.cfg` to `$HOME/Work/dotfiles`
- I renamed the command from `config` to `dotfiles`

My reason for changing the folder path, was:
- I wanted to store this `dotfiles` repository in my _work_ GitHub profile\
    &rarr; and to do that, I needed it to use my _work_ GitHub SSH key\
    &emsp;&rarr; and to do that, I needed to have the `dotfiles` git folder tracked under the `Work` folder on my laptop\
    &emsp;&emsp;&rarr; because my ~/.ssh/config and ~/.gitconfig_work depend on that `Work` folder path to function seamlessly

## Steps for using this repository if you are not `timweightman` (personal) or `timweightman-zai` (work)

1. In .ssh/config https://github.com/timweightman-zai/dotfiles/blob/master/.ssh/config
    - Update [line 4](https://github.com/timweightman-zai/dotfiles/blob/master/.ssh/config#L4) with your work SSH key file path
    - Update [line 10](https://github.com/timweightman-zai/dotfiles/blob/master/.ssh/config#L10) with your personal SSH key file path

1. In .gitconfig https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig
    - Make sure you are happy with the work and personal folder paths, I have used ~/Work and ~/Personal respectively

1. In .gitconfig-personal https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig-personal
    - Update [lines 2 and 3](https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig-personal#L2-L3) with your personal github email and user name
    - Update [line 5](https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig-personal#L5) with the correct file path for your personal github SSH key file

1. In .gitconfig-work https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig-work
    - Update [lines 2 and 3](https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig-work#L2-L3) with your work github email and user name
    - Update [line 5](https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig-work#L5) with the correct file path for your work github SSH key file
    - Update [lines 12 and 13](https://github.com/timweightman-zai/dotfiles/blob/master/.gitconfig-work#L12-L13) with your work github user name

1. In .zshrc https://github.com/timweightman-zai/dotfiles/blob/master/.zshrc
    - Update [lines 105 and 106](https://github.com/timweightman-zai/dotfiles/blob/master/.zshrc#L105-#L106) with the correct file paths for your work and personal SSH key files so they are automatically added to the SSH agent whenever you restart your machine / open a terminal
