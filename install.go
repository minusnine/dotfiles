package main

import (
	"flag"
	"fmt"
	"net/http"
	"io/ioutil"
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
		"man-db",
		"mercurial",
		"mosh",
		"nmap",
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
		"vim-nox",  // provides vim with python support
		"weechat-curses",
		"xbacklight",
		"xfce4-power-manager",
		"xfce4-pulseaudio-plugin",
		"xserver-xorg-input-synaptics",
		"xss-lock",
		"zip",
		"zsh",
	}

	removePackages = []string{
		"command-not-found",
	}

	gitRepos = map[string]string{
		"https://github.com/gmarik/Vundle.vim.git":       "~/.vim/bundle/Vundle.vim",
		"https://github.com/robbyrussell/oh-my-zsh.git":  "~/.oh-my-zsh",
		"https://github.com/minusnine/ericgar.com.git":   "~/src/ericgar.com",
		"https://github.com/tmux-plugins/tpm":            "~/.tmux/plugins/tpm",
		"https://go.googlesource.com/go":                 "~/src/go",
		"https://github.com/myusuf3/numbers.vim.git":     "~/.vim/bundle/numbers",
		"https://github.com/vim-syntastic/syntastic.git": "~/.vim/bundle/syntastic",
		"https://github.com/tmux/tmux.git": "~/src/tmux",
	}

	goPackages = []string{
		"github.com/tebeka/selenium",
		"github.com/pkg/sftp",
		"github.com/spf13/hugo",
	}

	dirs = []string{
		"~/.vim",
		"~/.vim/autoload",
		"~/tmp",
		"~/tmp/vim",
		"~/.ssh",
		"~/src",
		"~/bin",
		"~/.urxvt",
		"~/.urxvt/ext",
		"~/opt",
	}

	removeDirs = []string{
		"~/Desktop",
		"~/Documents",
		"~/Downloads",
		"~/Music",
		"~/Pictures",
		"~/Public",
		"~/Templates",
		"~/Videos",
	}
)
var (
	isRoot bool
	homeDir string
)

func main() {
	flag.Parse()

	u, err := user.Current()
	if err != nil {
		log.Exitf("Error getting current user: %v", err)
	}
	if u.Name == "root" {
		isRoot = true
	}
	homeDir = u.HomeDir

	if isRoot {
		managePackages()
		return
	}
	log.Infof("Re-run as root to install packages.")

	makeDirs()
	cloneGitRepos()
	installDotFiles()
	installRust() // must happen before setupVim
	setupVim()
	removeDefaultDirs()
	createSSHKey()
	setupUrxvt()
	installTmux()

	// TODO(ekg):
	// https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
	// /usr/lib/pm-utils/sleep.d/00xscreensaver
	// font
	// background
}

func installTmux() {
	if _, err := os.Stat(expandPath("~/opt/bin/tmux")); !os.IsNotExist(err) {
		log.V(1).Infof("~/opt/bin/tmux already exists, skipping build.")
		return
	}
	cmd := exec.Command("sh", "autogen.sh")
	cmd.Dir = expandPath("~/src/tmux")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running tmux autogen.sh: %s", err)
		return
	}

	cmd = exec.Command("./configure", "--prefix="+expandPath("~/opt"))
	cmd.Dir = expandPath("~/src/tmux")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running tmux configure: %s", err)
		return
	}

	cmd = exec.Command("make")
	cmd.Dir = expandPath("~/src/tmux")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running tmux make: %s", err)
		return
	}

	cmd = exec.Command("make", "install")
	cmd.Dir = expandPath("~/src/tmux")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running tmux make install: %s", err)
		return
	}
}

func setupUrxvt() {
	path := expandPath("~/.urxvt/ext/font-size")
	if _, err := os.Stat(path); err == nil {
		return
	}
	log.Infof("Installing the Urxvt font-size extension")
	script, err := downloadScript("https://raw.githubusercontent.com/majutsushi/urxvt-font-size/master/font-size")
	if err != nil {
		log.Errorf("Error downloading the URxvt font-size extension: %s", err)
		return
	}
	if err := ioutil.WriteFile(path, []byte(script), 0644); err != nil {
		log.Errorf("Error writing the URxvt font-size extension to %s: %s", path, err)
		return
	}
}

func installDotFiles() {
	baseDir := expandPath("~/go/src/github.com/minusnine/dotfiles/data")
	err := filepath.Walk(baseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Errorf("Error walking path %s: %s", path, err)
			return nil
		}
		suffixPath := strings.TrimPrefix(path, baseDir)
		target := expandPath("~"+suffixPath)

		if info.IsDir() {
			s, err := os.Stat(target)
			if err == nil && s.IsDir() {
				return nil
			} else if !os.IsNotExist(err) {
				log.Infof("Removing %s", target)
				if err := os.RemoveAll(target); err != nil {
					log.Errorf("Error removing %s: %s", target, err)
					return nil
				}
			}
			log.Infof("Making directory %s", target)
			if err := os.Mkdir(target, 0700); err != nil {
				log.Errorf("Error making directory %s: %s", target, err)
			}
		} else {
			r, err := os.Readlink(target)
			if err == nil && r == path {
				return nil
			} else if !os.IsNotExist(err) {
				log.Infof("Removing %s", target)
				if err := os.RemoveAll(target); err != nil {
					log.Errorf("Error removing %s: %s", target, err)
					return nil
				}
			}
			log.Infof("Symlinking %s to %s", path, target)
			if err := os.Symlink(path, target); err != nil {
				log.Errorf("Error symlinking dotfile %s to %s: %s", path, target, err)
			}
		}
		return nil
	})
	if err != nil {
		log.Errorf("Error installing dotfiles: %s", err)
	}
}

func createSSHKey() {
	path := expandPath("~/.ssh/id_rsa")
	if _, err := os.Stat(path); err == nil {
		return
	}
	cmd := exec.Command("ssh-keygen", "-f", path)
	cmd.Stdin = os.Stdin
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	if err := cmd.Run(); err != nil {
		log.Errorf("Error creating SSH key: %s", err)
	}
}

func downloadScript(url string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", fmt.Errorf("error downloading %s: %s", url, err)
	}
	defer resp.Body.Close()

	buf, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("error downloading %s: %s", url, err)
	}
	return string(buf), err
}

func runScript(script string) error {
	cmd := exec.Command("sh")
	cmd.Stdin = strings.NewReader(script)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func installRust() {
	if _, err := exec.LookPath("rust"); err == nil {
		return
	}
	if _, err := os.Stat(expandPath("~/.cargo/bin/rustc")); err == nil {
		return
	}

	script, err := downloadScript("https://sh.rustup.rs")
	if err != nil {
		log.Errorf("Error installing Rust: %s", err)
		return
	}

	if err := runScript(script); err != nil {
		log.Errorf("Error installing Rust: %s", err)
	}

	if _, err := exec.LookPath("rust"); err != nil {
		log.Error("Error instaling Rust: rust is not in $PATH after installation.")
	}
	return
}

func removeDefaultDirs() {
	for _, dir := range removeDirs {
		dir = expandPath(dir)
		if _, err := os.Stat(dir); err != nil {
			if !os.IsNotExist(err) {
				log.V(1).Infof("Error stat'ing directory %s: %s", dir, err)
			}
			continue
		}
		if err := os.RemoveAll(dir); err != nil {
			log.Errorf("Error removing directory %s: %s", dir, err)
		}
	}
}

func makeDirs() {
	for _, dir := range dirs {
		dir = expandPath(dir)
		if err := os.MkdirAll(dir, 0750); err != nil {
			log.Errorf("Error creating directory %v: %v", dir, err)
		}
	}
}

func expandPath(d string) string {
	return strings.Replace(d, "~", homeDir, 1)
}

func managePackages() {
	apt := manager.NewAptPackageManager()

	for _, pkg := range packages {
		if apt.IsInstalled(pkg) {
			log.V(1).Infof("Package %v already installed", pkg)
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

	installNode()
}

func cloneGitRepos() {
	for repo, dir := range gitRepos {
		dir = expandPath(dir)
		if err := os.MkdirAll(dir, 0750); err != nil {
			log.Errorf("Error creating directory %v for repository %v: %v", dir, repo, err)
			continue
		}
		if f, err := os.Open(filepath.Join(dir, ".git")); err == nil {
			f.Close()
			log.V(1).Infof("Repository %v already cloned into %v, skipping", repo, dir)
			continue

		}
		if err := exec.Command("git", "clone", repo, dir).Run(); err != nil {
			log.Errorf("Error cloning repository %v into %v: %v", repo, dir, err)
			continue
		}
		log.Infof("Cloned repository %v into %v", repo, dir)
	}
}

func downloadPathogen() {
	path := expandPath("~/.vim/autoload/pathogen.vim")
	if _, err := os.Stat(path); err == nil {
		return
	} else if !os.IsNotExist(err) {
		log.Errorf("Error stating %s: %s", path, err)
		return
	}
	log.Infof("Installing Pathogen")
	script, err := downloadScript("https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim")
	if err != nil {
		log.Errorf("Error downloading Pathogen: %s", err)
		return
	}
	if err := ioutil.WriteFile(path, []byte(script), 0644); err != nil {
		log.Errorf("Error writing Pathogen to %s: %s", path, err)
	}
}

func installVimPlugins() {
	cmd := exec.Command("vim", "+PluginInstall", "+qall", "-i", "NONE", "-o", "-")
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	if err := cmd.Run(); err != nil {
		log.Errorf("Error installing Vim plugins: %s", err)
	}
}

func installNode() {
	apt := manager.NewAptPackageManager()
	const pkg = "nodejs"
	if apt.IsInstalled(pkg) {
		log.V(1).Infof("Package %v already installed", pkg)
		return
	}

	script, err := downloadScript("https://deb.nodesource.com/setup_11.x")
	if err != nil {
		log.Errorf("Error downloading node repository creation script: %s", err)
		return
	}
	if err := runScript(script); err != nil {
		log.Errorf("Error installing node repository: %s", err)
	}

	log.Warningf("Package %v is not installed", pkg)
	if !isRoot {
		return
	}
	if err := apt.Install(pkg); err != nil {
		log.Errorf("Error installing package %q: %s", pkg, err)
		return
	}
	log.Infof("Installed package %v", pkg)
}

func installYCM() {
	if _, err := os.Stat(expandPath("~/.vim/bundle/YouCompleteMe/third_party/ycmd/ycm_core.so")); !os.IsNotExist(err) {
		log.V(1).Info("YouCompleteMe already installed")
		return
	}
	cmd := exec.Command(expandPath("~/.vim/bundle/YouCompleteMe/install.py"), "--gocode-completer", "--tern-completer", "--racer-completer")
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	if err := cmd.Run(); err != nil {
		log.Errorf("Error installing Vim plugins: %s", err)
	}
}

func setupVim() {
	downloadPathogen()

	installVimPlugins()  // must happen before installYCM
	installYCM()
}
