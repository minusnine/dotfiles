package main

var (
	dirs = []string{
		"~/.ssh",
		"~/.vim",
		"~/src",
		"~/tmp/vim",
	}

	// https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu

	aptPackages = []string{
		"tmux",
		"gcc",
		"mosh",
		"nmap",
		"subversion",
		"zsh",
		"libgmp-dev",
		"libmpfr-dev",
		"libmpc-dev",
		"libc6-dev-i386",
		"make",
		"g++",
		"flex",
	}

	goPackages = []string{
		"github.com/pkg/sftp",
		"github.com/spf13/hugo",
	}

	gitRepos = map[string]string{
		"https://go.googlesource.com/go":              "~/src/go",
		"git://github.com/robbyrussell/oh-my-zsh.git": "~/src/oh-my-zsh",
		"https://github.com/gmarik/vundle.git":        "~/.vim/bundle/vundle",
		"https://github.com/VundleVim/Vundle.vim.git": "~/.vim/bundle/Vundle.vim",
		"git@github.com:flazz/vim-colorschemes.git": "~/.vim/colors",
		"git@github.com:minusnine/ericgar.com.git": "~/src/ericgar.com",
	}

	files = map[string]string {
		".tmux.conf": "~/.tmux.conf",
		".vimrc": "~/.vimrc",
},
// Run sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

)

func main() {

}
