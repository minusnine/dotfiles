package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"os/user"
	"path"
	"path/filepath"
	"strings"
	"text/template"

	log "github.com/golang/glog"
	"github.com/juju/packaging/manager"
	yaml "gopkg.in/yaml.v2"
)

var facts struct {
	IsRoot           bool
	HomeDir          string
	DebianCodeName   string
	RealUser         string
	DotfilesDir      string
	Python3ConfigDir string
}

func main() {
	var (
		configPath = flag.String("config_path", "~/go/src/github.com/minusnine/dotfiles/config.yaml", "The path to the configuration file.")
		realUser   = flag.String("real_user", "", "The real user name. Pass when running as root.")
	)
	flag.Parse()

	populateFacts(*realUser, *configPath)

	if err := readConfig(*configPath); err != nil {
		log.Exit(err)
	}

	if facts.IsRoot {
		managePackages()
		manageGroups()
		return
	}
	log.Info("Not installing packages and groups as we are not root.")

	makeDirs()
	cloneGitRepos()
	installDotFiles()
	installRust() // must happen before setupVim
	setupVim()
	removeDefaultDirs()
	createSSHKey()
	setupUrxvt()
	installTmux()
	installGoPackages()

	// TODO(ekg):
	// /usr/lib/pm-utils/sleep.d/00xscreensaver
	// font
	// background
}

func populateFacts(realUser, configPath string) {
	u, err := user.Current()
	if err != nil {
		log.Exitf("Error getting current user: %v", err)
	}
	if u.Name == "root" {
		facts.IsRoot = true
		log.Info("Running as root.")

		// TODO(ekg): we could probably do this by inspecting parent processes
		// instead of requiring a parameter.
		if realUser == "" {
			log.Exit("--real_user must be supplied when running as root.")
		}
		u, err = user.Lookup(realUser)
		if err != nil {
			log.Exitf("Error looking up user %s: %s", realUser, err)
		}
		facts.RealUser = realUser
	}
	facts.HomeDir = u.HomeDir
	facts.DotfilesDir = expandPath(path.Dir(configPath))

	facts.DebianCodeName, err = debianCodeName()
	if err != nil {
		log.Exitf("Error looking up user %s: %s", realUser, err)
	}

	cmd := exec.Command("python3-config", "--configdir")
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		log.Exitf("Error running python3-config --configdir: %s", err)
	}
	facts.Python3ConfigDir = strings.TrimSpace(string(out))
}

func debianCodeName() (string, error) {
	buf, err := exec.Command("lsb_release", "--codename", "--short").Output()
	if err != nil {
		return "", fmt.Errorf("error determining Debian code name: %s", err)
	}
	return strings.TrimSpace(string(buf)), nil
}

var config struct {
	Directories struct {
		Create []string
		Remove []string
	}
	AptPackages struct {
		Install      []string
		Remove       []string
		Repositories map[string]struct {
			Distribution, Component, Key string
		}
	} `yaml:"apt-packages"`
	GoPackages      []string          `yaml:"go-packages"`
	GitRepositories map[string]string `yaml:"git-repositories"` // URL -> Directory
	Groups          []string
}

func readConfig(path string) error {
	data, err := ioutil.ReadFile(expandPath(path))
	if err != nil {
		return fmt.Errorf("error reading config file: %s", err)
	}

	tmpl, err := template.New("config").Parse(string(data))
	if err != nil {
		return fmt.Errorf("error parsing config file: %s", err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, facts); err != nil {
		return fmt.Errorf("error templating config file: %s", err)
	}

	if err := yaml.UnmarshalStrict(buf.Bytes(), &config); err != nil {
		return fmt.Errorf("error unmarshalling config file: %s", err)
	}

	return nil
}

func installGoPackages() {
	cmd := exec.Command("go", "list", "...")
	output, err := cmd.Output()
	if err != nil {
		log.Errorf("Error listing Go packages: %s", err)
		return
	}
	installed := map[string]bool{}
	for _, line := range strings.Split(string(output), "\n") {
		installed[line] = true
	}

	toInstall := map[string]bool{}
	for _, pkg := range config.GoPackages {
		if _, ok := installed[pkg]; !ok {
			toInstall[pkg] = true
		}
	}
	for pkg := range toInstall {
		log.Infof("Installing Go package %s", pkg)
		output, err := exec.Command("go", "get", "-v", pkg).CombinedOutput()
		if err != nil {
			log.Errorf("Error installing Go package %s: %s. Output:%s\n", pkg, err, output)
			continue
		}
		log.Infof("Go package %s installed", pkg)
	}
}

func manageGroups() {
	for _, name := range config.Groups {
		if _, err := user.LookupGroup(name); err != nil {
			if _, ok := err.(user.UnknownGroupError); ok {
				if err := exec.Command("addgroup", name).Run(); err != nil {
					log.Errorf("Error creating group %s: %s", name, err)
					continue
				}
			} else {
				log.Errorf("Error looking up group %s: %s", name, err)
				continue
			}
		}

		if err := exec.Command("adduser", facts.RealUser, name).Run(); err != nil {
			log.Errorf("Error adding user to group %s: %s", name, err)
		}
	}
}

func installTmux() {
	if _, err := os.Stat(expandPath("~/opt/bin/tmux")); !os.IsNotExist(err) {
		log.V(1).Infof("~/opt/bin/tmux already exists, skipping build.")
		return
	}
	log.Infof("Installing tmux from source")
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
		target := expandPath("~" + suffixPath)

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

func runScript(script string, args ...string) error {
	argv := []string{"-s", "--"}
	argv = append(argv, args...)
	cmd := exec.Command("bash", argv...)
	cmd.Stdin = strings.NewReader(script)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func runCommand(cmd string, args ...string) error {
	c := exec.Command(cmd, args...)
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return c.Run()
}

func installRust() {
	if _, err := exec.LookPath("rustc"); err == nil {
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

	if err := runScript(script, "-y"); err != nil {
		log.Errorf("Error installing Rust: %s", err)
	}

	if _, err := exec.LookPath("rust"); err != nil {
		log.Error("Error instaling Rust: rust is not in $PATH after installation.")
	}
	return
}

func removeDefaultDirs() {
	for _, dir := range config.Directories.Remove {
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
	for _, dir := range config.Directories.Create {
		dir = expandPath(dir)
		if err := os.MkdirAll(dir, 0750); err != nil {
			log.Errorf("Error creating directory %v: %v", dir, err)
		}
	}
}

func expandPath(d string) string {
	return strings.Replace(d, "~", facts.HomeDir, -1)
}

func managePackages() {
	addAptRepositories()

	apt := manager.NewAptPackageManager()

	for _, pkg := range config.AptPackages.Install {
		if apt.IsInstalled(pkg) {
			log.V(1).Infof("Package %v already installed", pkg)
			continue
		}
		log.Warningf("Package %v is not installed", pkg)
		if facts.IsRoot {
			log.Infof("Installing package %s", pkg)
			if err := apt.Install(pkg); err != nil {
				log.Errorf("Error installing package %s: %v", pkg, err)
			} else {
				log.Infof("Installed package %s successfully", pkg)
			}
		} else {
			log.Warningf("Skipping package %s installation", pkg)
		}
	}

	installNode()
}

func cloneGitRepos() {
	for repo, dir := range config.GitRepositories {
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
	log.Info("Installing/updating vim plugins")
	cmd := exec.Command("vim", "+PluginInstall!", "+qall", "-i", "NONE", "-o", "-")
	if err := cmd.Run(); err != nil {
		log.Errorf("Error installing Vim plugins: %s", err)
		return
	}
	log.Info("vim plugins installed/updated")
}

func installGoVimBinaries() {
	log.Info("Installing/updating go binaries for vim plugins")
	cmd := exec.Command("vim", "+GoInstallBinaries!", "+qall", "-i", "NONE", "-o", "-")
	if err := cmd.Run(); err != nil {
		log.Errorf("Error installing go binaries for vim plugins: %s", err)
		return
	}
	log.Info("go binaries for vim plugins installed/updated")

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
	if !facts.IsRoot {
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
	compileVim()
	downloadPathogen()

	installVimPlugins() // must happen before installYCM
	installYCM()
	installGoVimBinaries()
}

func compileVim() {
	if _, err := os.Stat(expandPath("~/opt/vim/bin/vim")); !os.IsNotExist(err) {
		log.V(1).Infof("~/opt/vim/bin/vim already exists, skipping build.")
		return
	}

	log.Infof("Compiling and installing vim")

	cmd := exec.Command("make", "distclean")
	cmd.Dir = expandPath("~/src/vim")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running vim make distclean: %s", err)
		return
	}

	cmd = exec.Command("./configure", []string{
		"--with-features=huge",
		"--enable-multibyte",
		"--enable-rubyinterp=yes",
		"--enable-python3interp=yes",
		"--with-python3-config-dir=" + facts.Python3ConfigDir,
		"--enable-perlinterp=yes",
		"--enable-luainterp=yes",
		"--enable-gui=gtk2",
		"--enable-cscope",
		"--prefix=" + expandPath("~/opt/vim")}...)
	cmd.Dir = expandPath("~/src/vim")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running tmux make install: %s", err)
		return
	}

	cmd = exec.Command("make")
	cmd.Dir = expandPath("~/src/vim")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running tmux make: %s", err)
		return
	}

	cmd = exec.Command("make", "install")
	cmd.Dir = expandPath("~/src/vim")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Errorf("Error running tmux make install: %s", err)
		return
	}
}

func addAptRepositories() {
	apt := manager.NewAptPackageManager()

	for _, pkg := range []string{"software-properties-common", "gnupg2"} {
		if !apt.IsInstalled(pkg) {
			log.Infof("Installing package %s", pkg)
			if err := apt.Install(pkg); err != nil {
				log.Errorf("Error installing package %s: %s", pkg, err)
				return
			}
		}
	}

	// TODO(ekg): only do this conditionally and apt-get update if added
	for url, spec := range config.AptPackages.Repositories {
		if spec.Key != "" {
			log.Infof("Adding key for Apt repository %s from %s", url, spec.Key)
			if buf, err := exec.Command("apt-key", "add", spec.Key).CombinedOutput(); err != nil {
				log.Errorf("Error adding key for Apt repository %s from %s: %s. Output:\n%s", url, spec.Key, err, buf)
				continue
			}
		}

		args := []string{"deb", url, spec.Distribution, spec.Component}
		log.Infof("Adding Apt repository %s: add-apt-repository %v", url, args)
		if buf, err := exec.Command("apt-add-repository", strings.Join(args, " ")).CombinedOutput(); err != nil {
			log.Warning("apt-add-repository ", strings.Join(args, " "))
			log.Errorf("Error adding repository %s: %s", url, buf)
		}
	}
	if buf, err := exec.Command("apt-get", "update").CombinedOutput(); err != nil {
		log.Errorf("Error updating apt: %s", buf)
	}
}
