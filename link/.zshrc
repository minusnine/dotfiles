# Path to your oh-my-zsh configuration.
ZSH=$HOME/.dotfiles/libs/oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="ekg"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git tmux golang battery git-extras)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
SHELL=/usr/bin/zsh
# save tons of history. Since zsh is smart enough to share a history file
# I can use the same history file on ALL machines!
export SAVEHIST=100000
export HISTSIZE=100000
export HISTFILESIZE=10000
export HISTFILE="${HOME}/.zhistory"

# Enable prompt variable subsitution 
setopt prompt_subst 

# share history between shells
setopt share_history inc_append_history

# Expand braces A string of the form `foo{xx,yy,zz}bar' is expanded to th
#e individual words `fooxxbar', `fooyybar' and `foozzbar'. 
# This breaks ksh compatibility. use setopt no_brace_ccl if this becomes 
#an issue
setopt brace_ccl 

# don't store the history command in the history file
setopt hist_no_store 

# Don't enter duplicates into the history file
setopt hist_ignore_all_dups

# Don't kill background jobs on shell exit, and don't prompt me that ther
#e are background jobs left
setopt no_hup no_check_jobs 

# if a command is entered that isn't a command but a directory, cd into 
# that directory
setopt auto_cd 
# list choices on an ambiguous completion
setopt auto_list 

# this seems like an odd option
# setopt autoresume \

# Use extened glob characters # ~ ^
setopt extendedglob 

# Don't require ./ to match explicitly
setopt glob_dots

# list jobs in long format
setopt longlistjobs 

# Don't allow redirection to clobber existing files
setopt noclobber 

# Recognize exact matches even if they are ambiguous
setopt recexact 

# Crazy things with completion and the cursor
setopt complete_in_word 

# Allow echo "hello" > testfile | less    (implicit tees)
setopt multios 

# Allow the short syntax of loops
setopt short_loops 

# Don't let background jobs run by default at a lower priority
setopt no_bg_nice 

# Make the completion list happen on the second tab
setopt bash_auto_list

# Don't cycle through completions by hitting tab, bash style
setopt no_menu_complete
setopt no_auto_menu

# Print exit value. This is marginally useful
#setopt print_exit_value

# Make the cursor go to the end if completion is requested
setopt alwaystoend
# allow use of spaces in a string to separate array values
setopt sh_word_split

# Make completion faster by using a cache
zstyle ':completion:*' use-cache on

# resolve users, like ~gleasob
zstyle ':completion:*' users resolve

# completer defines functions that act as algorithms to use to complete
# _expand  - I don't really understand this
# _complete - actually do completion
zstyle ':completion:*' completer _expand _complete

# Make the popup menu colored like in ls
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Enable advanced zsh completion. This must happen *after* setting up com
#pletion parameters
# autoload -U compinit
# compinit -u

# Enable colors
# autoload -U colors
# colors

# Make the tab completion list colored just like ls
# ZLS_COLORS=$LS_COLORS

# I'm not sure why this is necessary, but I think it's just
# syntactic and useful
local GRAY=$'%{\e[1;30m%}'
local LIGHT_GRAY=$'%{\e[0;37m%}'
local WHITE=$'%{\e[1;37m%}'
local LIGHT_BLUE=$'%{\e[1;36m%}'
local YELLOW=$'%{\e[1;33m%}'
local PURPLE=$'%{\e[1;35m%}'
local GREEN=$'%{\e[1;32m%}'
local BLUE=$'%{\e[1;34m%}'
local RESET=$'%{\e[0m%}'

# I type `ls` so often, why should I type *two whole letters* that are on
# *opposite sides of the keyboard*? I shouldn't. I can just type `l` [Enter].
alias l="ls";

# Same idea as above. I've moved 7 keystrokes into 3.
alias la="ls -al";

# Same idea as above. I've moved 6 keystrokes into 3.
alias ll="ls -l";

# I constantly need to cd backwards. `cd .. [Enter]` is 6 keystrokes
# My alias is only two...
alias b="cd .. && ls"

export EDITOR="vim";
export PAGER=less

#
# Since zsh doesn't use readline, it doesn't respect my inputrc
# 
# This file can be generated via: zsh /usr/share/zsh/functions/Misc/zkbd

source ~/.zkbd/$TERM

#
# So, make the home and end keys work properly
#
bindkey "${key[Home]}" beginning-of-line
bindkey "${key[End]}" end-of-line

#
# History search. Type 'ls' then [PgUp] for backward search
#
bindkey "${key[PageUp]}" history-beginning-search-backward
bindkey "${key[PageDown]}" history-beginning-search-forward

if [ -d "$HOME/src/go" -a -x "$HOME/src/go/bin/go" ]; then
  export GOROOT="$HOME/src/go"
  export PATH="$PATH:$HOME/src/go/bin"
fi
