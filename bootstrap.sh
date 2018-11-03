#!/bin/sh 

set -e

DOTFILES_DIR=~/go/src/github.com/minusnine
if [ ! -e ${DOTFILES_DIR} ]; then
	mkdir -p ${DOTFILES_DIR}
	cd $DOTFILES_DIR
	git clone https://github.com/minusnine/dotfiles
fi
DOTFILES_DIR="${DOTFILES_DIR}/dotfiles"

if [ ! -e /usr/bin/go ]; then
	sudo apt-get install golang
fi

if [ ! -e ~/src/go/bin/go ]; then
	if [ ! -e ~/src/go ]; then
		git clone https://go.googlesource.com/go
	fi
	cd ~/src/go
	git checkout go1.11.2
	cd ~/src/go/src
	./all.bash
fi

PATH="${HOME}/go/bin:${PATH}"
cd $DOTFILES_DIR
go get -t ./...
go run ${DOTFILES_DIR}/install.go --alsologtostderr
sudo GOPATH=/home/ekg/go go run ${DOTFILES_DIR}/install.go --alsologtostderr
