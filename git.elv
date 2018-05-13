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
each [c]{ completions[$c] = [ [_]{ -git-opts $c } ] } $-cmds

-aliases = [(git config --list | each [l]{ re:find '^alias\.([^=]+)=(.*)$' $l })[groups][1 2][text]]
put $-aliases[(range (count $-aliases) &step=2 | each [x]{ put $x':'(+ $x 2) })] | each [p]{
  if (has-key $completions $p[1]) {
    completions[$p[0]] = $p[1]
  } else {
    completions[$p[0]] = []
  }
}

completions[add] =      [ [_]{ -git-opts add      ; MOD-UNTRACKED      }              ]
completions[stage] =    add
completions[checkout] = [ [_]{ -git-opts checkout ; MODIFIED; BRANCHES }              ]
completions[mv] =       [ [_]{ -git-opts mv       ; TRACKED            }              ]
completions[rm] =       [ [_]{ -git-opts rm       ; TRACKED            }              ]
completions[diff] =     [ [_]{ -git-opts diff     ; TRACKED; BRANCHES  }              ]
completions[push] =     [ [_]{ -git-opts push     ; REMOTES            } [_]{ BRANCHES } ]
completions[merge] =    [ [_]{ -git-opts merge    ; BRANCHES           }              ]

completions[-opts] = [_]{ -git-opts }

fn git-completer [gitcmd @rest]{
  status = (git:status)
  comp:subcommands $completions $gitcmd $@rest
}

edit:completion:arg-completer[git] = $git-completer~
