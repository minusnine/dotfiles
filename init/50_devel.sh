# Load npm_globals, add the default node into the path.
source ~/.dotfiles/source/50_devel.sh

directories=(
  ~/go
  ~/src
  ~/tmp
  ~/tmp/vim
)

for directory in "${directory[@]}"; do
  if [[ ! -d "$directory" ]]; then
    mkdir "$directory"
  fi
done

