package main

import (
	"flag"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strings"

	log "github.com/golang/glog"
	"github.com/juju/packaging/manager"
)

var (
	packages = []string{
		"apt-transport-https",
		"automake",
		"build-essential",
		"cmake",
		"dnsutils",
		"fonts-inconsolata",
		"fonts-go",
		"gcc",
		"gimp",
		"git",
		"htop",
		"i3",
		"i3lock",
		"id3tool",
		"libevent-dev",
		"libgit2-dev",
		"libncurses5-dev",
		"libssl-dev",
		"libusb-1.0.0-dev",
		"mercurial",
		"mosh",
		"nmap",
		"nodejs",
		"parallel",
		"powertop",
		"python3-dev",
		"python-dev",
		"python-pip",
		"rofi",
		"sl",
		"subversion",
		"tmux",
		"tree",
		"unzip",
		"weechat-curses",
		"xbacklight",
		"xfce4-power-manager",
		"xfce4-pulseaudio-plugin",
		"xserver-xorg-input-synaptics",
		"xss-lock",
		"zip",
	}

	removePackages = []string{
		"command-not-found",
	}

	gitRepos = map[string]string{
		"https://github.com/gmarik/Vundle.vim.git":       "~/.vim/bundle/Vundle.vim",
		"https://github.com/robbyrussell/oh-my-zsh.git":  "~/src/oh-my-zsh",
		"https://github.com/minusnine/ericgar.com.git":   "~/src/ericgar.com",
		"https://github.com/tmux-plugins/tpm":            "~/.tmux/plugins/tpm",
		"https://go.googlesource.com/go":                 "~/src/go",
		"https://github.com/flazz/vim-colorschemes.git":  "~/.vim/colors",
		"https://github.com/myusuf3/numbers.vim.git":     "~/.vim/bundle/numbers",
		"https://github.com/vim-syntastic/syntastic.git": "~/.vim/bundle/syntastic",
	}

	goPackages = []string{
		"github.com/tebeka/selenium",
		"github.com/pkg/sftp",
		"github.com/spf13/hugo",
	}

	dirs = []string{
		"~/.vim",
		"~/.vim/tmp",
		"~/.ssh",
		"~/src",
		"~/bin",
	}
)

func main() {
	// mkdir ~/src
	// git clone git@github.com:minusnine/dotfiles.git ~/src/dotfiles
	// go get .
	// go run install.go --alsologtostderr
	// sudo go GOPATH=/home/ekg/go run install.go --alsologtostderr

	flag.Parse()
	if isRoot {
		managePackages()
		return
	}
	log.Infof("Re-run as root to install packages.")
	makeDirs()
	cloneGitRepos()
	setupVim()

	// TODO(ekg):
	// Run sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	// https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
	// sudo pip install Pygments
	// /usr/lib/pm-utils/sleep.d/00xscreensaver
	// font
	// background
	// for i in ~/src/dotfiles/data/.* ; do ln -sf $i ~/$(basename $i) ; done
	// mkdir -p ~/.urxvt/ext
	// curl -fsSL https://raw.githubusercontent.com/majutsushi/urxvt-font-size/master/font-size > ~/.urxvt/ext/font-size
	// curl https://sh.rustup.rs -sSf | sh
	// mkdir ~/opt
	// cd src/tmux
	// sh autogen.sh
	// ./configure --prefix=/home/eric/opt && make
	// rm -rf Desktop Documents Downloads Music Pictures Public Templates/ Videos

}

func makeDirs() {
	for _, dir := range dirs {
		dir = expandDir(dir)
		if err := os.MkdirAll(dir, 0750); err != nil {
			log.Errorf("Error creating directory %v: %v", dir, err)
		}
	}
}

var isRoot bool
var homeDir string

func init() {
	u, err := user.Current()
	if err != nil {
		log.Exitf("Error getting current user: %v", err)
	}
	if u.Name == "root" {
		isRoot = true
	}
	homeDir = u.HomeDir
}

func expandDir(d string) string {
	return strings.Replace(d, "~", homeDir, 1)
}

func managePackages() {
	apt := manager.NewAptPackageManager()

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

func cloneGitRepos() {
	for repo, dir := range gitRepos {
		dir = expandDir(dir)
		if err := os.MkdirAll(dir, 0750); err != nil {
			log.Errorf("Error creating directory %v for repository %v: %v", dir, repo, err)
			continue
		}
		if f, err := os.Open(filepath.Join(dir, ".git")); err == nil {
			f.Close()
			log.Infof("Repository %v already cloned into %v, skipping", repo, dir)
			continue

		}
		if err := exec.Command("git", "clone", repo, dir).Run(); err != nil {
			log.Errorf("Error cloning repository %v into %v: %v", repo, dir, err)
			continue
		}
		log.Infof("Cloned repository %v into %v", repo, dir)
	}
	// cd ~/.vim
	// git submodule add -f https://github.com/flazz/vim-colorschemes.git bundle/colorschemes
}

func setupVim() {
	// mkdir -p ~/tmp/vim
	// mkdir -p ~/.vim/autoload
	// curl https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim -sSf > ~/.vim/autoload/pathogen.vim
	// run  vim +PluginInstall +qall
	// cd ~/.vim/bundle/YouCompleteMe
	// ./install.py --gocode-completer --tern-completer  --racer-completer
	// curl -fsSL https://www.vim.org/scripts/download_script.php?src_id=11430 > ~/.vim/colors/colors/tir_black.vim
}
