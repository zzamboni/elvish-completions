use ./comp
use re
use github.com/muesli/elvish-libs/git
use github.com/zzamboni/elvish-modules/util

-cmds = [ (git help -a | eawk [line @f]{ if (re:match '^  [a-z]' $line) { put $@f } }) ]
aliases = [(git config --list | each [line]{
      if (re:match '^alias\.' $line) { re:replace '^alias\.([^=]+)=.*$' '${1}' $line }
})]
commands = [$@-cmds $@aliases]
status = [&]

fn -run-git-cmd [gitcmd @rest]{
  gitcmds = [$gitcmd]
  if (eq (kind-of $gitcmd) string) {
    gitcmds = [(splits " " $gitcmd)]
  }
  cmd = $gitcmds[0]
  if (eq (kind-of $cmd) string) {
    cmd = (external $cmd)
  }
  if (> (count $gitcmds) 1) {
    $cmd (explode $gitcmds[1:]) $@rest
  } else {
    $cmd $@rest
  }
}

fn MODIFIED-FILES  { explode $status[local-modified] }
fn UNTRACKED-FILES { explode $status[untracked] }
fn TRACKED-FILES   { git ls-files }
fn BRANCHES        { git branch --list --all --format '%(refname:short)' }
fn REMOTES         { git remote }

git-completions = [
  &-opts= [
    (man git | each [l]{
        re:find '(--\w[\w-]*)' $l; re:find '\s(-\w)\W' $l
    })[groups][1][text]
  ]
  &add=      [ { MODIFIED-FILES; UNTRACKED-FILES } ]
  &stage=    add
  &checkout= [ { MODIFIED-FILES; BRANCHES }        ]
  &mv=       [ $TRACKED-FILES~                     ]
  &rm=       mv
  &diff=     rm
  &push=     [ $REMOTES~ $BRANCHES~                ]
  &merge=    [ $BRANCHES~                          ]
]

fn git-completer [gitcmd @rest]{
  status = (git:status)
  comp:subcommands $git-completions $gitcmd $@rest
}

edit:completion:arg-completer[git] = $git-completer~
