use ./comp
use re
use github.com/muesli/elvish-libs/git
use github.com/zzamboni/elvish-modules/util

completions = [&]

status = [&]

option-style = gray

fn -run-git-cmd [gitcmd @rest]{
  gitcmds = [$gitcmd]
  if (eq (kind-of $gitcmd) string) {
    gitcmds = [(splits " " $gitcmd)]
  }
  cmd = $gitcmds[0]
  if (eq (kind-of $cmd) string) {
    cmd = (external $cmd)
  }
  $cmd (explode $gitcmds[1:]) $@rest
}

fn -git-opts [@cmd]{
  -line = ''
  regex = '(?:-(\w),?\s*)?(?:--([\w-]+).*?)?\s\s(\w.*)$'
  if (eq $cmd []) {
    regex = '()--(\w[\w-]*)()'
  }
  _ = ?(git $@cmd -h 2>&1) | drop 1 | each [l]{
    if (re:match '^\s+\w' $l) {
      put $-line$l
      -line = ''
    } else {
      put $-line
      -line = $l
    }
  } |
  comp:extract-opts &regex=$regex
}

fn MODIFIED      { explode $status[local-modified] }
fn UNTRACKED     { explode $status[untracked] }
fn MOD-UNTRACKED { MODIFIED; UNTRACKED }
fn TRACKED       { _ = ?(git ls-files 2>/dev/null) }
fn BRANCHES      { _ = ?(git branch --list --all --format '%(refname:short)' 2>/dev/null) }
fn REMOTES       { _ = ?(git remote 2>/dev/null) }

git help -a | eawk [line @f]{ if (re:match '^  [a-z]' $line) { put $@f } } | each [c]{
  completions[$c] = [
    &-opts= { -git-opts $c }
    &-seq= [ ]
  ]
}

git config --list | each [l]{ re:find '^alias\.([^=]+)=(.*)$' $l } | each [m]{
  alias target = $m[groups][1 2][text]
  if (has-key $completions $target) {
    completions[$alias] = $target
  } else {
    completions[$alias] = [ &-seq= [] ]
  }
}

completions[add][-seq]      = [ $MOD-UNTRACKED~ ... ]
completions[stage]          = add
completions[checkout][-seq] = [ { MODIFIED; BRANCHES } ... ]
completions[mv][-seq]       = [ $TRACKED~ ... ]
completions[rm][-seq]       = [ $TRACKED~ ... ]
completions[diff][-seq]     = [ { MODIFIED; BRANCHES  } ... ]
completions[push][-seq]     = [ $REMOTES~ $BRANCHES~ ]
completions[merge][-seq]    = [ $BRANCHES~ ... ]
completions[init][-seq]     = [ [stem]{ put "."; comp:files $stem &dirs-only } ]
completions[branch][-seq]   = [ $BRANCHES~ ... ]

completions[-opts] = { -git-opts }

fn git-completer [gitcmd @rest]{
  status = (git:status)
  comp:expand $completions $gitcmd $@rest
}

edit:completion:arg-completer[git] = $git-completer~
