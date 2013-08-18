# This file is sourced by all *interactive* zsh shells on startup,
# including some apparently interactive shells such as scp and rcp
# that cant tolerate any output.
# Accordingly, test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]]; then
    # Shell is non-interactive.  Be done now
    return
fi

# colors for ls
if [[ -f ~/.dir_colors ]]; then
    eval `dircolors -b ~/.dir_colors`;
elif [[ -f /etc/DIR_COLORS ]]; then
    eval `dircolors -b /etc/DIR_COLORS`;
fi

alias ls="ls --color=auto";

# -U makes the discards duplicate entries in arrays
typeset -U path cdpath fpath manpath

# This is a good idea to put functions one per file. 
#fpath+=(/ms/user/g/garride/bin/functions)

autoload append
autoload prepend
autoload module

# Autoload all of the functions in fpath
autoload $^fpath/*(N:t)

# save tons of history. Since zsh is smart enough to share a history file
# I can use the same history file on ALL machines!
export SAVEHIST=100000
export HISTSIZE=100000
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

# if a command is entered that isn't a command but a directory, cd into t
#hat directory
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
autoload -U compinit
compinit -u

# Enable colors
autoload -U colors
colors

# Make the tab completion list colored just like ls
ZLS_COLORS=$LS_COLORS

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


HOSTNAME=`hostname`
# Set up the left prompt. %~ is the path
PROMPT='$GRAY${USER}@${HOSTNAME} %~ $ $RESET'

# Set up the right prompt. %h is the command number and %T is the time
# RPROMPT="$BLUE%h $YELLOW%T$WHITE"
 # I *know* we're in zsh as we're sourcing .zshrc
export SHELL=`which zsh`
export shell=zsh

# TETRIS ON THE COMMAND LINE! YES!
autoload -U tetris
zle -N tetris
# Note: the following introduces a small delay when typing ' t' which cou
#ld be annoyting
#bindkey tet tetris

# make my delete key work on the command line
bindkey -v 'ESC[3~' delete-char

# Make STDERR color red
# This causes a race condition with the prompt. no good.
#exec 2>>(while read line; do
#  print '\e[91m'${(q)line}'\e[0m' > /dev/tty; done &)

# Get the DBA environment
# The setopts are needed because the /ms/dist/*/env_* scripts are 
# written to test for the existence of folders using raw globbing in the 
# condition of an if statement, so it throws an error when those are not
# found. NONOMATCH disables error reporting when globbing comes up empty
# We re-enable it afterward

# For some reason, there is always a
# core file waiting for me when ksh runs
# so just delete it.
if [[ -h ~/core ]]; then
    rm -f ~/core;
fi
ulimit -c 0;

# I type `ls` so often, why should I type *two whole letters* that are on
# *opposite sides of the keyboard*? I shouldn't. I can just type `l` [Enter].
alias l="ls";

# Same idea as above. I've moved 7 keystrokes into 3.
alias la="ls -al";

# Same idea as above. I've moved 6 keystrokes into 3.
alias ll="ls -l";

# I hate temporary files that are left after editing. I want
# an easy way to delete them
alias clean="rm *~ #*"

# I constantly need to cd backwards. `cd .. [Enter]` is 6 keystrokes
# My alias is only two...
alias b="cd .. && ls"

# I logout every session. Why not have a one button escape? Useful
# for those nested SSH sessions.
alias x="exit"

## CVS command section
alias cvsstat="cvs status 2>&1 | egrep '(^\? |Status: )' | grep -v Up-to-date"

alias xdg-open open

# I've joined the ranks of uber-nerds and am a vim supporter
if [[ -a `which vim` ]] ; then
    export EDITOR="vim";
else
        export EDITOR="vi";
fi

export HOST=`hostname`
export EDITOR=vim
export PAGER=less
export HISTFILESIZE=10000
export PRINTER=npp906

set -o emacs

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

alias psg="ps -ef | grep"

export JAVA_HOME=/usr/lib/jvm/java-6-openjdk/

export PATH=$PATH:/var/lib/gems/1.8/bin
