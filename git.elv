use ./comp
use re
use github.com/muesli/elvish-libs/git
use github.com/zzamboni/elvish-modules/util

completions = [&]

status = [&]

modified-style  = yellow
untracked-style = red
tracked-style   = ''
branch-style    = blue
remote-style    = cyan

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

fn -git-opts [@cmd &regex='^\s*(?:-(\w),?\s*)?(?:--([\w-]+))?.*?\s\s(\w.*)$']{
  -line = ''
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
  } | comp:extract-opts &regex=$regex
}

fn MODIFIED      { explode $status[local-modified] | comp:decorate &style=$modified-style }
fn UNTRACKED     { explode $status[untracked] | comp:decorate &style=$untracked-style }
fn MOD-UNTRACKED { MODIFIED; UNTRACKED }
fn TRACKED       { _ = ?(-run-git-cmd git ls-files 2>/dev/null) | comp:decorate &style=$tracked-style }
fn BRANCHES      [&all=$false]{
  -allarg = []
  if $all { -allarg = ['--all'] }
  _ = ?(-run-git-cmd git branch --list (explode $-allarg) --format '%(refname:short)' 2>/dev/null |
comp:decorate &display-suffix=' (branch)' &style=$branch-style) }
fn REMOTES       { _ = ?(-run-git-cmd git remote 2>/dev/null | comp:decorate &style=$remote-style ) }

git-completions = [
  &add=      [ $MOD-UNTRACKED~ ... ]
  &stage=    add
  &checkout= [ { MODIFIED; BRANCHES } ... ]
  &mv=       [ $TRACKED~ ... ]
  &rm=       [ $TRACKED~ ... ]
  &diff=     [ { MODIFIED; BRANCHES  } ... ]
  &push=     [ $REMOTES~ { BRANCHES &all } ]
  &merge=    [ $BRANCHES~ ... ]
  &init=     [ [stem]{ put "."; comp:files $stem &dirs-only } ]
  &branch=   [ $BRANCHES~ ... ]
]

git help -a | eawk [line @f]{ if (re:match '^  [a-z]' $line) { put $@f } } | each [c]{
  seq = [ ]
  if (has-key $git-completions $c) {
    seq = $git-completions[$c]
  }
  if (eq (kind-of $seq 'string')) {
    completions[$c] = $seq
  } else {
    completions[$c] = (comp:sequence $seq &opts={ -git-opts $c })
  }
}

git config --list | each [l]{ re:find '^alias\.([^=]+)=(.*)$' $l } | each [m]{
  alias target = $m[groups][1 2][text]
  if (has-key $completions $target) {
    completions[$alias] = $target
  } else {
    completions[$alias] = (comp:sequence [])
  }
}

edit:completion:arg-completer[git] = (comp:subcommands $completions \
  &pre-hook=[@_]{ status = (git:status) } &opts={ -git-opts }
)
