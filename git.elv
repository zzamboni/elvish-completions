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
  _ = ?(git add -h) | each [l]{
    re:find '(?:-(\w),\s*)?--([\w-]+).*?\s\s(\w.*)$' $l
  } | each [m]{
    short long desc = $m[groups][1 2 3][text]
    opt = [&]
    if (not-eq $short '') { opt[short] = $short }
    if (not-eq $long  '') { opt[long]  = $long  }
    if (not-eq $desc  '') { opt[desc]  = $desc  }
    put $opt
  }
}

fn MODIFIED      [@_]{ explode $status[local-modified] }
fn UNTRACKED     [@_]{ explode $status[untracked] }
fn MOD-UNTRACKED [@_]{ MODIFIED; UNTRACKED }
fn TRACKED       [@_]{ _ = ?(git ls-files 2>/dev/null) }
fn BRANCHES      [@_]{ _ = ?(git branch --list --all --format '%(refname:short)' 2>/dev/null) }
fn REMOTES       [@_]{ _ = ?(git remote 2>/dev/null) }

git help -a | eawk [line @f]{ if (re:match '^  [a-z]' $line) { put $@f } } | each [c]{
  completions[$c] = [
    &-opts= { -git-opts $c }
    &-seq= [ { comp:empty } ]
  ]
}

git config --list | each [l]{ re:find '^alias\.([^=]+)=(.*)$' $l } | each [m]{
  alias target = $m[groups][1 2][text]
  if (has-key $completions $target) {
    completions[$alias] = $target
  } else {
    completions[$alias] = { comp:empty }
  }
}

completions[add] = [
  &-opts= { -git-opts add }
  &-seq= [ $MOD-UNTRACKED~ ... ]
]
completions[stage] =    add
completions[checkout] = [
  &-opts= { -git-opts checkout }
  &-seq= [ [_]{ MODIFIED; BRANCHES } ... ]
]
completions[mv] = [
  &-opts= { -git-opts mv }
  &-seq= [ $TRACKED~ ... ]
]
completions[rm] = [
  &-opts= { -git-opts rm }
  &-seq= [ $TRACKED~ ... ]
]
completions[diff] = [
  &-opts= { -git-opts diff }
  &-seq= [ [_]{ MODIFIED; BRANCHES  } ... ]
]
completions[push] = [
  &-opts= { -git-opts push }
  &-seq= [ $REMOTES~ $BRANCHES~ ]
]
completions[merge] = [
  &-opts= { -git-opts merge }
  &-seq= [ $BRANCHES~ ... ]
]

completions[-opts] = { -git-opts }

fn git-completer [gitcmd @rest]{
  status = (git:status)
  comp:expand $completions $gitcmd $@rest
}

edit:completion:arg-completer[git] = $git-completer~
