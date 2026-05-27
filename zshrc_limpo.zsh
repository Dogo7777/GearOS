# ==========================================
# .zshrc - GearOS Edition (Bootc Optimized)
# ==========================================

# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to Oh My Zsh (instalação global ou via skel)
export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Carrega o Oh My Zsh
source $ZSH/oh-my-zsh.sh 2>/dev/null || true

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Powerlevel10k Config (se existir)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
