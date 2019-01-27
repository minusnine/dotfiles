#!/bin/bash

set -e

while getopts sc o
do
  case "$o" in
	s) build_from_source=1;;
  c) skip_clone=1;;
	[?])	echo "Usage: $0 [-s] " >&2
		exit 1;;
	esac
done

sudo apt-get --no-install-recommends -y install ca-certificates gcc golang git lsb-release ssh

if [[ ${build_from_source} -eq 1 && ! -e ~/src/go/bin/go ]]; then
	if [ ! -e ~/src/go ]; then
		git clone https://go.googlesource.com/go ~/src/go
	fi
	cd ~/src/go
  latest=$(git describe --tags `git rev-list --tags --max-count=1`)
	git checkout ${latest}
  exit
	cd ~/src/go/src
	./all.bash
fi

# TODO(ekg): handle this clone better to avoid clobbering a Docker local copy.
DOTFILES_DIR=~/go/src/github.com/minusnine
if [ ${skip_clone} -eq 1 ]; then
  DOTFILES_DIR="${DOTFILES_DIR}/dotfiles"
else
  echo "Cloning dotfiles to $DOTFILES_DIR"
  if [ ! -e ${DOTFILES_DIR} ]; then
    mkdir -p ${DOTFILES_DIR}
    git clone https://github.com/minusnine/dotfiles ${DOTFILES_DIR}
  fi
  DOTFILES_DIR="${DOTFILES_DIR}/dotfiles"
fi

PATH="${HOME}/go/bin:${PATH}"
cd $DOTFILES_DIR
export GOPATH=${HOME}/go
go get -t ./...
sudo GOPATH=$GOPATH go run ${DOTFILES_DIR}/install.go --alsologtostderr --real_user=$USER
go run ${DOTFILES_DIR}/install.go --alsologtostderr
