#!/bin/bash

printf 'Repacking repo...\n'
printf 'If the next line reads "DONE!", something went wrong.\n'

git submodule foreach --recursive git ls-files -s | $(
  case "$1" in (-h)
    printf 'usage: git repack-symlinks [symlink] [symlink] [...]\n'
    return 0
  esac
  case $# in
    (0) git ls-files -s | grep -E '^120000' | cut -f2 ;;
    (*) printf '%s\n' "$@" ;;
  esac | while IFS= read -r symlink; do
    git update-index --no-assume-unchanged "$symlink"
    rmdir "$symlink" >/dev/null 2>&1
	printf '%s\n' "$symlink"
    git checkout -- "$symlink"
    printf 'Restored git symlink: %s -> %s\n' "$symlink" "$(cat "$symlink")"
  done
  
  printf '\n'
)



read -p "DONE! Press [ENTER] to exit."