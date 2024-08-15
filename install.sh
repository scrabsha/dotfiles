#! /bin/bash

function die {
  echo "Error: $1"
  exit 101
}

PRETEND="no"
FORCE="no"

# CLI arg parsing
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --pretend|-p) PRETEND="yes";;

    --force|-f) FORCE="yes";;

    *) die "unknown parameter: $1"
  esac

  shift
done

readonly PRETEND
readonly FORCE

function run {
  command="$1"

  if [[ "$PRETEND" = "yes" ]]; then
    echo "$1"
  else
    eval "$command"

    if [[ "$?" -ne "0" ]]; then
      die "\"$command\" exited with non-zero status"
    fi
  fi
}

# install_file repo_path real_path
function install_file {
  src=$(realpath "$1")
  dst="/home/$USER/$2"

  if [[ -f "$dst" ]]; then
    if [[ -L "$dst" || "$FORCE" = "no" ]]; then
      run "rm \"$dst\""
    else
      die "file \"$dst\" already exists"
    fi
  fi

  run "ln -sf \"$src\" \"$dst\""
}

function install_from_dir {
  dir="$1"
  links_file="$dir/links.txt"

  if [[ ! -f "$links_file" ]]; then
    die "$links_file does not exist"
  fi

  while read -r line; do
    src=$(echo "$line" | cut -d":" -f1)
    dst=$(echo "$line" | cut -d" " -f2)

    echo "  - $src"
    install_file "$dir/$src" "$dst"
  done < "$links_file"
}

find -name "links.txt" \
| while read -r file; do
  dir=$(dirname "$file")
  echo "- $dir"
  install_from_dir "$dir"
done 
