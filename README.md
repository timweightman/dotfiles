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
