## File reads from a custom zshenv file that we have.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Add all the customizations
[[ -f $CUSTOM_ZSH/dracula.zsh ]] && source $CUSTOM_ZSH/dracula.zsh
[[ -f $CUSTOM_ZSH/logger.zsh ]] && source $CUSTOM_ZSH/logger.zsh


# Add our plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Now start
source $ZSH/oh-my-zsh.sh

# Now add our custom profile
[[ ! -f $CUSTOM_ZSH/.p10k.zsh ]] || source $CUSTOM_ZSH/.p10k.zsh
