package main

import (
	"os"
	"os/user"

	log "github.com/golang/glog"
	"github.com/juju/utils/packaging/manager"
	git "github.com/libgit2/git2go"
)

var (
	packages = []string{
		"automake",
		"build-essential",
		"git-core",
		"gimp",
		"fonts-inconsolata",
		"htop",
		"id3tool",
		"libevent-dev",
		"libncurses5-dev",
		"libgit2",
		"libssl-dev",
		"mosh",
		"nmap",
		"powertop",
		"sl",
		"tree",
		"mercurial",
		"python-pip",
		"xbacklight",
		"xfce4-mixer", // for tray utilities only
		"xfce4-power-manager",
		"xscreensaver",
	}
	removePackages = []string{
		"command-not-found",
	}

	gitRepos = map[string]string{
		"https://github.com/gmarik/Vundle.vim.git":      "/home/ekg/.vim/bundle/Vundle.vim",
		"https://github.com/robbyrussell/oh-my-zsh.git": "/home/ekg/src/oh-my-zsh",
		"https://github.com/minusnine/ericgar.com.git":  "/home/ekg/src/ericgar.com",
		"git@github.com:minusnine/camlistore.git":       "/home/ekg/src/camlistore",
		"https://github.com/tmux-plugins/tpm", "/home/ekg/.tmux/plugins/tpm",
		// TODO(ekg): also compile this.
		"https://github.com/tmux/tmux.git": "/home/ekg/src/tmux",
		"https://go.googlesource.com/go":              "~/src/go",
		"git@github.com:flazz/vim-colorschemes.git": "~/.vim/colors",
	}

	goPackages = []string{
		"github.com/minusnine/taowm",
		"github.com/tebeka/selenium",
		"github.com/pkg/sftp",
		"github.com/spf13/hugo",
	}

	dirs = []string{
		"src",
		".vim",
		"tmp/vim",
		"~/.ssh",
		"~/.vim",
		"~/src",
		"~/tmp/vim",

	}
)
// Run sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
// https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu

func main() {
	packages()
	dirs()
	gitRepos()
	vim()

	// TODO(ekg):
	// sudo pip install Pygments
	// /usr/lib/pm-utils/sleep.d/00xscreensaver
	// font
	// background
	// dotfiles
}

func dirs() {
	for _, dir := range dirs {
		if err := os.MkdirAll(dir); err != nil {
			log.Errorf("Error creating directory %v: %v", dir, err)
		}
	}
}

func packages() {
	apt := manager.NewAptPackageManager()

	var isRoot bool
	u, err := user.Current()
	if err != nil {
		log.Errorf("Error getting current user: %v", err)
	} else if u.Name == "root" {
		isRoot = true
	}
	for _, pkg := range packages {
		if apt.IsInstalled(pkg) {
			log.Infof("Package %v already installed", pkg)
			continue
		}
		log.Warningf("Package %v is not installed", pkg)
		if isRoot {
			if err := apt.Install(pkg); err != nil {
				log.Errorf("Error installing %s: %v\n", pkg, err)
			} else {
				log.Infof("Installed package %v successfully", pkg)
			}
		} else {
			log.Warningf("Skipping package installation for %v", pkg)
		}
	}
}

func gitRepos() {
	for repo, dir := range gitRepos {
		if err := os.MkdirAll(dir); err != nil {
			log.Errorf("Error creating directory %v for repository %v: %v", dir, repo, err)
			continue
		}

		if _, err := git.Clone(repo, dir, nil); err != nil {
			log.Errorf("Error cloning repository %v into %v: %v", repo, dir, err)
			continue
		}
		log.Infof("Cloned repository %v into %v", repo, dir)
	}
}

func vim() {

	// mkdir ~/tmp/vim
	// install ~/.vimrc
	// clone vundle
	// run  vim +PluginInstall +qall
}