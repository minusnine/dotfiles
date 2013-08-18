# This file is sourced by all *interactive* shells on startup,
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

# save tons of history. Since is smart enough to share a history file
# I can use the same history file on ALL machines!
export SAVEHIST=100000
export HISTSIZE=100000
export HISTCONTROL=ignoredups
export HISTFILE=~/.bash_history
export HISTTIMEFORMAT="%d/%m/%y %T "
shopt -s histappend

#
# Save and read the history every time the prompt is printed. This allows
# multiple shells to share the same history file. NB: there may still be a race
# condition here due to lack of locking (where zsh is better).
#
PROMPT_COMMAND="history -a; history -n"

#
# determines whether multi-line commands are stored in the history as a single
# command (on) or not (off; default).
#
shopt -s cmdhist

#
# Save multiline commands with newlines instead of semicolons
#
shopt -s lithist


#
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
#
shopt -s checkwinsize

#
# CDPATH is like PATH but for `cd': cd searches this path if the suggested
# directory doesn't exist. This is useful for changing to commonly-used
# directories.
#
CDPATH="$CDPATH:${HOME}/src"
export CDPATH

#
# No need to type 'cd' when changing to a directory.
#
shopt -s autocd

#
# Auto-correct typos to cd
#
shopt -s cdspell

#
# TODO: investigate the usefulness of this
#
# shopt -s histreedit

#
# make less more friendly for non-text input files, see lesspipe(1)
#
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# Please sir, don't core.
# ulimit -c 0;

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

# pushd and popd are like back and forward in a browser and are efficient.
alias c="pushd"
alias p="popd"
alias d="dirs"  # list directories on the stack

# I logout every session. Why not have a one button escape? Useful
# for those nested SSH sessions.
alias x="exit"

# Easy process search
alias psg="ps -ef | grep"

# I've joined the ranks of uber-nerds and am a vim supporter
export EDITOR="vim";
set -o vi

# Get me to the root of my src tree quickly
alias g='$(g3)'

# Various important variable assignments
export HOST=$(hostname)
export HOSTNAME=$HOST
export PAGER=less
export HISTFILESIZE=10000

# Mousemode alias so the mouse works in WeeChat while running mosh:
alias mousemode="perl -E ' print \"\e[?1005h\e[?1002h\" '"
 
# Command function to enable mousemode, get the mosh key and port, lookup the ip for the hostname and set up the mosh-client connection
function mosher() {
  mousemode
  mosh_string=$(ssh $1 -t mosh-server|grep "MOSH CONNECT")
  mosh_key=$(echo $mosh_string|cut -d " " -f4)
  mosh_port=$(echo $mosh_string|cut -d " " -f3)
  mosh_ip=$(ping -n -c 1 $1 | grep PING | cut -d '(' -f 2|cut -d ')' -f 1)
  MOSH_KEY=$(echo $mosh_key) mosh-client $(echo $mosh_ip) $(echo $mosh_port)
}

export GOROOT=/home/ekg/src/go
export GOPATH=/home/ekg/go
export PATH="/home/ekg/src/go/bin:$PATH

source ~/.custom/bashrc
