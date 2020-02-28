#!/bin/bash

echo "Create a new symlinked file or directory. Keep in mind that the source MUST be a path relative to the location of target!"
echo "Eg.:
	source: ../source.txt
	target: target/source.txt"
printf "\n"
read -p "Which file or directory do you want to symlink (source)? `echo $'\n> '`" src
printf "\n"
read -p "Where should I put the created symlink (target)? `echo $'\n> '`" target
printf "\n"

if [[ -z "src" ]]; then
    echo "Please supply a valid source file or directory."
    exit 1
elif [[ -z "target" ]]; then
    echo "Please supply a valid location for the resulting symlink."
    exit 1
fi

set -- "$src" "$target"

  if [ $# -ne 2 ] || [ "$1" = "-h" ]; then
    printf '%b\n' \
        'usage: git add-symlink <source_file_or_dir> <target_symlink>\n' \
        'Create a symlink in a git repository on a Windows host.\n' \
        'Note: source MUST be a path relative to the location of target'
    [ "$1" = "-h" ] && return 0 || return 2
  fi

  source_file_or_dir=${1#./}
  source_file_or_dir=${source_file_or_dir%/}

  target_symlink=${2#./}
  target_symlink=${target_symlink%/}
  target_symlink="${GIT_PREFIX}${target_symlink}"
  target_symlink=${target_symlink%/.}
  : "${target_symlink:=.}"

  if [ -d "$target_symlink" ]; then
    target_symlink="${target_symlink%/}/${source_file_or_dir##*/}"
  fi

  case "$target_symlink" in
    (*/*) target_dir=${target_symlink%/*} ;;
    (*) target_dir=$GIT_PREFIX ;;
  esac

  target_dir=$(cd "$target_dir" && pwd)

  if [ ! -e "${target_dir}/${source_file_or_dir}" ]; then
    printf 'error: git-add-symlink: %s: No such file or directory\n' \
        "${target_dir}/${source_file_or_dir}" >&2
    printf '(Source MUST be a path relative to the location of target!)\n' >&2
    return 2
  fi

  git update-index --add --cacheinfo 120000 \
      "$(printf '%s' "$source_file_or_dir" | git hash-object -w --stdin)" \
      "${target_symlink}" \
    && git checkout -- "$target_symlink" \
    && printf '%s -> %s\n' "${target_symlink#$GIT_PREFIX}" "$source_file_or_dir" \
    || return $?

printf "\n"
read -p "DONE! Press [ENTER] to exit."
