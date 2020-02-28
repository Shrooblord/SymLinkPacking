# Symlinks on Windows
Using symlinks in git environments is an easy and convenient way to link two remotely located projects together and work within the one, centralised repository.

Unfortunately, creating symlinks of files the generic way on Windows causes git to submit the file as a hardlink instead, completely counteracting the point of using symlinks. So we'll have to install custom git commands in order to be able to work with our sub-projects in tandem and maintain proper symlinks in git commits.

**ATTENTION!** Using the scripts or the manual commands below internally performs a `git checkout`, which could have potentially destructive consequences when used on a working directory with uncommitted files. Only use these files after you have committed or stashed your changes!

## What Do?
These scripts are intended to be used to unpack and repack symlinks included in specifically the submodules of a given git repository.

When checking out a git repo using symlinks, before using the environment on your Windows machine, run `unpack-repo.sh` or `up-symlinks-recur`. Before pushing to the remote from Windows (but after committing!), run `repack-repo.sh` or `rp-symlinks-recur`.

## Give It to Me Nice and Easy
Execute the shell scripts `unpack-repo.sh`, `repack-repo.sh` or `add-symlink.sh` as required; read on below for more information.

Note that for git to operate on the symlinks, it needs to know about them. So initialise your symlinks (`git add-symlink`).

## I Want to Do It Manually!
You need to modify your global user `.gitconfig` in your home directory for git (`C:\Users\YOURNAME\.gitconfig` in a typical installation) to add the following three commands:
`git add-symlink`; `git unpack-symlinks` & `git repack-symlinks`.

To do that, paste the following at the end of your `.gitconfig`file in order to create the three aliases required:

```
[alias]
	add-symlink = "!__git_add_symlink() {\n  if [ $# -ne 2 ] || [ \"$1\" = \"-h\" ]; then\n    printf '%b\\n'         'usage: git add-symlink <source_file_or_dir> <target_symlink>\\n'         'Create a symlink in a git repository on a Windows host.\\n'         'Note: source MUST be a path relative to the location of target'\n    [ \"$1\" = \"-h\" ] && return 0 || return 2\n  fi\n\n  source_file_or_dir=${1#./}\n  source_file_or_dir=${source_file_or_dir%/}\n\n  target_symlink=${2#./}\n  target_symlink=${target_symlink%/}\n  target_symlink=\"${GIT_PREFIX}${target_symlink}\"\n  target_symlink=${target_symlink%/.}\n  : \"${target_symlink:=.}\"\n\n  if [ -d \"$target_symlink\" ]; then\n    target_symlink=\"${target_symlink%/}/${source_file_or_dir##*/}\"\n  fi\n\n  case \"$target_symlink\" in\n    (*/*) target_dir=${target_symlink%/*} ;;\n    (*) target_dir=$GIT_PREFIX ;;\n  esac\n\n  target_dir=$(cd \"$target_dir\" && pwd)\n\n  if [ ! -e \"${target_dir}/${source_file_or_dir}\" ]; then\n    printf 'error: git-add-symlink: %s: No such file or directory\\n'         \"${target_dir}/${source_file_or_dir}\" >&2\n    printf '(Source MUST be a path relative to the location of target!)\\n' >&2\n    return 2\n  fi\n\n  git update-index --add --cacheinfo 120000       \"$(printf '%s' \"$source_file_or_dir\" | git hash-object -w --stdin)\"       \"${target_symlink}\"     && git checkout -- \"$target_symlink\"     && printf '%s -> %s\\n' \"${target_symlink#$GIT_PREFIX}\" \"$source_file_or_dir\"     || return $?\n}\n__git_add_symlink"
	unpack-symlinks = "!__git_unpack_symlinks() {\n  case \"$1\" in (-h)\n    printf 'usage: git unpack-symlinks [symlink] [symlink] [...]\\n'\n    return 0\n  esac\n  ppid=$$\n  case $# in\n    (0) git ls-files -s | grep -E '^120000' | cut -f2 ;;\n    (*) printf '%s\\n' \"$@\" ;;\n  esac | while IFS= read -r symlink; do\n    case \"$symlink\" in\n      (*/*) symdir=${symlink%/*} ;;\n      (*) symdir=. ;;\n    esac\n\n    git checkout -- \"$symlink\"\nsrc=\"$(readlink -f \"$symlink\")\"\n\nposix_to_dos_sed='s_^/\\([A-Za-z]\\)_\\1:_;s_/_\\\\\\\\_g'\n    doslnk=$(printf '%s\\n' \"$symlink\" | sed \"$posix_to_dos_sed\")\n    dossrc=$(printf '%s\\n' \"$src\" | sed \"$posix_to_dos_sed\")\n\nif [ -f \"$src\" ]; then\n      rm -f \"$symlink\"\n      cmd //C mklink //H \"$doslnk\" \"$dossrc\"\n    elif [ -d \"$src\" ]; then\n      rm -f \"$symlink\"\n      cmd //C mklink //D \"$doslnk\" \"$dossrc\"\n    else\n      printf 'error: git-rm-symlink: Not a valid source\\n' >&2\n      printf '%s =/=> %s  (%s =/=> %s)...\\n'           \"$symlink\" \"$src\" \"$doslnk\" \"$dossrc\" >&2\n      false\n    fi || printf 'ESC[%d]: %d\\n' \"$ppid\" \"$?\"\n\n    git update-index --assume-unchanged \"$symlink\"\n  done | awk '\n    BEGIN { status_code = 0 }\n    /^ESC\\['\"$ppid\"'\\]: / { status_code = $2 ; next }\n    { print }\n    END { exit status_code }\n  '\n}\n__git_unpack_symlinks"
	unpack-symlink = !git unpack-symlinks
	up-symlinks-recur = !git submodule foreach --recursive git unpack-symlinks
	repack-symlinks = "!__git_repack_symlinks() {\n  \n  case \"$1\" in (-h)\n    printf 'usage: git repack-symlinks [symlink] [symlink] [...]\\n'\n    return 0\n  esac\n  case $# in\n    (0) git ls-files -s | grep -E '^120000' | cut -f2 ;;\n    (*) printf '%s\\n' \"$@\" ;;\n  esac | while IFS= read -r symlink; do\n    git update-index --no-assume-unchanged \"$symlink\"\n    rmdir \"$symlink\" >/dev/null 2>&1\nprintf '%s\\n' \"$symlink\"\n    git checkout -- \"$symlink\"\n    printf 'Restored git symlink: %s -> %s\\n' \"$symlink\" \"$(cat \"$symlink\")\"\n  done\n  \n}\n__git_repack_symlinks"
	rp-symlinks = !git repack-symlinks
	rp-symlinks-recur = !git submodule foreach --recursive git repack-symlinks
```


Git commands adapted from Mark G., courtesy of [this](https://stackoverflow.com/a/16754068) **Stack Overflow** post.

For your information, the symlinks created are always symlinks while in "git form" (`git add-symlink` or `git submodule foreach --recursive git repack-symlinks` (or: `git rp-symlinks-recur`)), are a hardlink for files while in "Windows form", and are symlinks for directories while in "Windows form" (`git submodule foreach --recursive git unpack-symlinks` (or: `git up-symlinks-recur`)).

### Example Use of add-symlink.sh
We run `add-symlink.sh` and are presented with two questions: what is the source file or directory, and what is the target location to put the created symlink?
Imagine the following folder structure:
```
MySource/
        |--ImportantFolder/
	|--source.txt
MyTarget/
```
We wish to include a symlink of `MySource/source.txt` in `MyTarget`, and also a symlink to `MySource/ImportantFolder` in `MyTarget`. To do this, we run the `add-symlink.sh` script twice.

The first time, when prompted for a source location, we type `../MySource/source.txt`. For the target, we type `MyTarget/source.txt`. This will create a symlink in `MyTarget` to the `MySource/source.txt` file.

On the second run, we instead enter the following for source and target, respectively: `../MySource/ImportantFolder`, then `MyTarget/ImportantFolder`. This will create a symlink in `MyTarget` to the `MySource/ImportantFolder` directory.

The resulting file structure will look like this:
```
MySource/
        |--ImportantFolder/
	|--source.txt
MyTarget/
        |--ImportantFolder*/
	|--source.txt*
```
where the `source.txt` file and `ImportantFolder` within `MyTarget` are symlinks, not actual files.