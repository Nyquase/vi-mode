# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
  zle && { zle -R; zle reset-prompt }
}

bindkey -v

typeset -A key
key=(
  Home       "${terminfo[khome]}"
  End        "${terminfo[kend]}"
  Insert     "${terminfo[kich1]}"
  Delete     "${terminfo[kdch1]}"
  Up         "${terminfo[kcuu1]}"
  Down       "${terminfo[kcud1]}"
  Left       "${terminfo[kcub1]}"
  Right      "${terminfo[kcuf1]}"
  PageUp     "${terminfo[kpp]}"
  PageDown   "${terminfo[knp]}"
)

# Fix backspace when leaving normal mode
bindkey "^?" backward-delete-char

# Setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey "${key[Home]}" beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey "${key[End]}" end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey "${key[Insert]}" overwrite-mode
[[ -n "${key[Delete]}"    ]] && bindkey "${key[Delete]}" delete-char
[[ -n "${key[Up]}"        ]] && bindkey "${key[Up]}" up-line-or-beginning-search
[[ -n "${key[Down]}"      ]] && bindkey "${key[Down]}" down-line-or-beginning-search
[[ -n "${key[PageUp]}"    ]] && bindkey "${key[PageUp]}" beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey "${key[PageDown]}" end-of-buffer-or-history
[[ -n "${key[Home]}"      ]] && bindkey -M vicmd "${key[Home]}" beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -M vicmd "${key[End]}" end-of-line
bindkey -M vicmd "k" up-line-or-beginning-search
bindkey -M vicmd "j" down-line-or-beginning-search

# Better searching in command mode
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M vicmd '/' history-incremental-search-forward

# Remap ctrl-U to default behavior
bindkey "^U" kill-whole-line

# Allow Ctrl-v to edit the command line
autoload -Uz edit-command-line
bindkey -M vicmd '^V' edit-command-line

# (vi-mode) allow ctrl-p, ctrl-n for navigate history (standard behaviour)
bindkey '^P' up-history
bindkey '^N' down-history

# (vi-mode) allow ctrl-h, ctrl-w, for char and word deletion (standard behaviour)
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word

# (vi-mode) allow ctrl-r to perform backward search in history
bindkey '^r' history-incremental-search-backward

# (vi-mode) allow ctrl-a and ctrl-e to move to beginning/end of line
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

export KEYTIMEOUT=1

function select_cursor() {
  case $KEYMAP in
    # Block cursor in normal and visual mode
    vicmd) echo -ne "\e[2 q";;
    # Line cursor in insert mode
    main|viins) echo -ne "\e[5 q";;
    # Else Block cursor
    *) echo -ne "\e[2 q";;
  esac
}

# Updates editor information when the keymap changes.
function zle-keymap-select() {
  zle reset-prompt
  zle -R
  select_cursor
}
zle -N zle-keymap-select

function zle-line-init() {
  echoti smkx
  zle reset-prompt
  select_cursor
}
zle -N zle-line-init

# Reset to block cursor when executing a command,
# else it would be line cursor
function zle-line-finish() {
  echoti rmkx
  echo -ne "\e[2 q"
}
zle -N zle-line-finish

# From spectrum.zsh
# FX=(
#   reset     "%{[00m%}"
#   bold      "%{[01m%}" no-bold      "%{[22m%}"
#   italic    "%{[03m%}" no-italic    "%{[23m%}"
#   underline "%{[04m%}" no-underline "%{[24m%}"
#   blink     "%{[05m%}" no-blink     "%{[25m%}"
#   reverse   "%{[07m%}" no-reverse   "%{[27m%}"
#   )

function vi_mode_prompt_info() {
  if [[ -z "$NORMAL_MODE_INDICATOR" ]]; then
    NORMAL_MODE_INDICATOR="%{$FX[bold]$FG[012]%}NORMAL%{$FX[reset]%}"
  fi
  if [[ -z "$INSERT_MODE_INDICATOR" ]]; then
    INSERT_MODE_INDICATOR="%{$FX[bold]$FG[008]%}INSERT%{$FX[reset]%}"
  fi
  if [[ -z "$VISUAL_MODE_INDICATOR" ]]; then
    VISUAL_MODE_INDICATOR="%{$FX[bold]$FG[214]%}VISUAL%{$FX[reset]%}"
  fi
  case $KEYMAP in
    vivis|vivli) echo -n "$VISUAL_MODE_INDICATOR";;
    vicmd) echo -n "$NORMAL_MODE_INDICATOR";;
    main|viins) echo -n "$INSERT_MODE_INDICATOR";;
  esac
}

if [[ -z "$RPS1" && -z "$RPROMPT" ]]; then
  RPS1='$(vi_mode_prompt_info)'
  RPS2=$RPS1
fi

# Helper function to display color code with a certain text 
# Useful to choose the mode indicator prompt
function spectrum_xls() {
  local SPECTRUM_TEXT
  if [[ -z $1 ]]; then
    SPECTRUM_TEXT="$ZSH_SPECTRUM_TEXT"
  else
    SPECTRUM_TEXT="$1"
  fi

  for code in {000..255}; do
		print -P -- "$code: %{$FX[bold]$FG[$code]%}$SPECTRUM_TEXT%{$FX[reset]%}"
	done
}
