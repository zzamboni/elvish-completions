use ./comp
use re
use github.com/muesli/elvish-libs/git
use github.com/zzamboni/elvish-modules/util

completions = [&]

-cmds = [ (git help -a | eawk [line @f]{ if (re:match '^  [a-z]' $line) { put $@f } }) ]
each [c]{ completions[$c] = [] } $-cmds

-aliases = [(git config --list | each [l]{ re:find '^alias\.([^=]+)=(.*)$' $l })[groups][1 2][text]]
put $-aliases[(range (count $-aliases) &step=2 | each [x]{ put $x':'(+ $x 2) })] | each [p]{
  if (has-key $completions $p[1]) {
    completions[$p[0]] = $p[1]
  } else {
    completions[$p[0]] = []
  }
}

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
  $cmd (explode $gitcmds[1:]) $@rest
}

fn MODIFIED-FILES  { explode $status[local-modified] }
fn UNTRACKED-FILES { explode $status[untracked] }
fn TRACKED-FILES   { git ls-files }
fn BRANCHES        { git branch --list --all --format '%(refname:short)' }
fn REMOTES         { git remote }

completions[add] =      [ { MODIFIED-FILES; UNTRACKED-FILES } ]
completions[stage] =    add
completions[checkout] = [ { MODIFIED-FILES; BRANCHES }        ]
completions[mv] =       [ $TRACKED-FILES~                     ]
completions[rm] =       mv
completions[diff] =     rm
completions[push] =     [ $REMOTES~ $BRANCHES~                ]
completions[merge] =    [ $BRANCHES~                          ]

completions[-opts] = [
  (git --help | each [l]{
      re:find '(--\w[\w-]*)' $l; re:find '[^-](-\w)\W' $l
  })[groups][1][text]
]

fn git-completer [gitcmd @rest]{
  status = (git:status)
  comp:subcommands $completions $gitcmd $@rest
}

edit:completion:arg-completer[git] = $git-completer~
