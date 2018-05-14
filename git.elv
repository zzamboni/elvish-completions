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
  opts = [(_ = ?(git $@cmd -h 2>&1) | each [l]{
      re:find '(--\w[\w-]*)' $l
  })[groups][1][text]]
  map = [&]
  each [k]{ map[$k] = $true } $opts
  keys $map | comp:decorate &style=$option-style
}

fn MODIFIED      { explode $status[local-modified] }
fn UNTRACKED     { explode $status[untracked] }
fn MOD-UNTRACKED { MODIFIED; UNTRACKED }
fn TRACKED       { _ = ?(git ls-files 2>/dev/null) }
fn BRANCHES      { _ = ?(git branch --list --all --format '%(refname:short)' 2>/dev/null) }
fn REMOTES       { _ = ?(git remote 2>/dev/null) }

-cmds = [ (git help -a | eawk [line @f]{ if (re:match '^  [a-z]' $line) { put $@f } }) ]
each [c]{ completions[$c] = [ { -git-opts $c } ] } $-cmds

-aliases = [(git config --list | each [l]{ re:find '^alias\.([^=]+)=(.*)$' $l })[groups][1 2][text]]
put $-aliases[(range (count $-aliases) &step=2 | each [x]{ put $x':'(+ $x 2) })] | each [p]{
  if (has-key $completions $p[1]) {
    completions[$p[0]] = $p[1]
  } else {
    completions[$p[0]] = []
  }
}

completions[add] = [
  &-opts= { -git-opts add }
  &-seq= [ { MOD-UNTRACKED } ]
]
completions[stage] =    add
completions[checkout] = [
  &-opts= { -git-opts checkout }
  &-seq= [ { MODIFIED; BRANCHES } ]
]
completions[mv] = [
  &-opts= { -git-opts mv }
  &-seq= [ { TRACKED } ]
]
completions[rm] = [
  &-opts= { -git-opts rm }
  &-seq= [ { TRACKED } ]
]
completions[diff] = [
  &-opts= { -git-opts diff }
  &-seq= [ { MODIFIED; BRANCHES  } ]
]
completions[push] = [
  &-opts= { -git-opts push }
  &-seq= [ { REMOTES } { BRANCHES } ]
]
completions[merge] = [
  &-opts= { -git-opts merge }
  &-seq= [ { BRANCHES } ]
]

completions[-opts] = { -git-opts }

fn git-completer [gitcmd @rest]{
  status = (git:status)
  comp:subcommands $completions $gitcmd $@rest
}

edit:completion:arg-completer[git] = $git-completer~
