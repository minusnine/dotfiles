#!/bin/bash
#
# Options:
#
# -s: Build Go from source. If not provided, then just use the package.
#
set -e
set -x

while getopts s o
do
  case "$o" in
	s) build_from_source=1;;
	[?])	echo "Usage: $0 [-s] " >&2
		exit 1;;
	esac
done

if [ ! -x /usr/bin/gcc ]; then
	echo "Installing gcc"
	sudo apt-get --no-install-recommends -y install --quiet gcc
	echo "gcc installed"
fi
if [ ! -x /usr/bin/git ]; then
	echo "Installing git"
	sudo apt-get --no-install-recommends -y install --quiet git
	echo "git installed"
fi
if [ ! -x /usr/bin/go ]; then
	echo "Installing go"
	sudo apt-get --no-install-recommends -y install --quiet golang
	echo "go installed"
fi
if [ ! -x /usr/bin/lsb_release ]; then
	echo "Installing lsb_release"
	sudo apt-get --no-install-recommends -y install --quiet lsb-release
	echo "lsb_release installed"
fi
if [ ! -x /usr/bin/ssh ]; then
	echo "Installing ssh"
	sudo apt-get --no-install-recommends -y install --quiet ssh
	echo "ssh installed"
fi
if [ ! -d /usr/share/ca-certificates ]; then
	echo "Installing ca-certificates"
	sudo apt-get --no-install-recommends -y install --quiet ca-certificates
	echo "ca-certificates installed"
fi

if [[ ${build_from_source} -eq 1 ]] && [ ! -e ~/src/go/bin/go ]; then
	if [ ! -e ~/src/go ]; then
		git clone https://go.googlesource.com/go ~/src/go
	fi
	cd ~/src/go
	latest=$(git describe --tags `git rev-list --tags --max-count=1`)
  echo "Building go version ${latest}"
	git checkout ${latest}
	cd ~/src/go/src
	./all.bash
fi
PATH="${HOME}/go/bin:${PATH}"

DOTFILES_DIR=~/go/src/github.com/minusnine/dotfiles
DOTFILES_URL="https://github.com/minusnine/dotfiles"

if [ ! -e ${DOTFILES_DIR} ]; then
	echo "Cloning dotfiles to $DOTFILES_DIR"
	git clone ${DOTFILES_URL} ${DOTFILES_DIR}
elif [ ! -e ${DOTFILES_DIR}/.git ]; then
	echo "Pulling dotfiles in $DOTFILES_DIR"
	mkdir -p ${DOTFILES_DIR}
	git -C ${DOTFILES_DIR} init
	git -C ${DOTFILES_DIR} remote add origin ${DOTFILES_URL} || /bin/true
	git -C ${DOTFILES_DIR} pull
fi

if [ ! -e ~/src/dotfiles ]; then
	[ -e ~/src ] || mkdir ~/src
	ln -sf $DOTFILES_DIR ~/src/dotfiles
fi

cd $DOTFILES_DIR
export GOPATH=${HOME}/go
go get -t ./...
sudo GOPATH=$GOPATH go run ${DOTFILES_DIR}/install.go --alsologtostderr --real_user=$USER
go run ${DOTFILES_DIR}/install.go --alsologtostderr
