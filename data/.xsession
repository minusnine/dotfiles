xsetroot -solid black &
gnome-screensaver &
setxkbmap -option terminate:ctrl_alt_bksp &
nm-applet --sm-disable &
eval `ssh-agent`
xmodmap $HOME/.xmodmaprc
google-chrome &
gnome-terminal --hide-menubar -e "tmux attach -d -t 0 || tmux new -t 0"
/home/ekg/go/bin/taowm
