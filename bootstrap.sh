#!/bin/sh 

set -e

if [ ! -e /usr/bin/gcc ]; then
  sudo apt-get -y install gcc
fi

if [ ! -e /usr/bin/go ]; then
	sudo apt-get -y install golang
fi

if [ ! -e /usr/bin/git ]; then
	sudo apt-get -y install git
fi

if [ ! -e ~/src/go/bin/go ]; then
	if [ ! -e ~/src/go ]; then
		git clone https://go.googlesource.com/go ~/src/go
	fi
	cd ~/src/go
  latest=$(git describe --tags `git rev-list --tags --max-count=1`)
	git checkout ${latest}
	cd ~/src/go/src
	./all.bash
fi

DOTFILES_DIR=~/go/src/github.com/minusnine
if [ ! -e ${DOTFILES_DIR} ]; then
	mkdir -p ${DOTFILES_DIR}
	cd $DOTFILES_DIR
	git clone https://github.com/minusnine/dotfiles
fi
DOTFILES_DIR="${DOTFILES_DIR}/dotfiles"

PATH="${HOME}/go/bin:${PATH}"
cd $DOTFILES_DIR
export GOPATH=${HOME}/go
go get -t ./...
sudo GOPATH=$GOPATH go run ${DOTFILES_DIR}/install.go --alsologtostderr --real_user=$USER
go run ${DOTFILES_DIR}/install.go --alsologtostderr
