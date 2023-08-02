use ./comp
use re
use str
use github.com/muesli/elvish-libs/git
use github.com/zzamboni/elvish-modules/util

var completions = [&]

var status = [&]

var git-arg-completer = { }

var git-command = git

var modified-style  = yellow
var untracked-style = red
var tracked-style   = $nil
var branch-style    = blue
var remote-style    = cyan
var unmerged-style  = magenta

fn -run-git {|@rest|
  var gitcmds = [$git-command]
  if (eq (kind-of $git-command) string) {
    set gitcmds = [(re:split " " $git-command)]
  }
  var cmd = $gitcmds[0]
  if (eq (kind-of $cmd) string) {
    set cmd = (external $cmd)
  }
  $cmd (all $gitcmds[1..]) $@rest
}

fn -git-opts {|@cmd|
  set _ = ?(-run-git $@cmd -h 2>&1) | drop 1 | if (eq $cmd []) {
    comp:extract-opts &fold=$true &regex='--(\w[\w-]*)' &regex-map=[&long=1]
  } else {
    comp:extract-opts &fold=$true
  }
}

fn MODIFIED      { all $status[local-modified] | comp:decorate &style=$modified-style }
fn UNTRACKED     { all $status[untracked] | comp:decorate &style=$untracked-style }
fn UNMERGED      { all $status[unmerged] | comp:decorate &style=$unmerged-style }
fn MOD-UNTRACKED { MODIFIED; UNTRACKED }
fn TRACKED       { set _ = ?(-run-git ls-files 2>&-) | comp:decorate &style=$tracked-style }
fn BRANCHES      {|&all=$false &branch=$true|
  var -allarg = []
  var -branch = ''
  if $all { set -allarg = ['--all'] }
  if $branch { set -branch = ' (branch)' }
  set _ = ?(-run-git branch --list (all $-allarg) --format '%(refname:short)' 2>&- |
  comp:decorate &display-suffix=$-branch &style=$branch-style)
}
fn REMOTE-BRANCHES {
  set _ = ?(-run-git branch --list --remote --format '%(refname:short)' 2>&- |
    grep -v HEAD |
    each {|branch| re:replace 'origin/' '' $branch } |
  comp:decorate &display-suffix=' (remote branch)' &style=$branch-style)
}
fn REMOTES       { set _ = ?(-run-git remote 2>&- | comp:decorate &display-suffix=' (remote)' &style=$remote-style ) }
fn STASHES       { set _ = ?(-run-git stash list 2>&- | each {|l| put [(re:split : $l)][0] } ) }

var git-completions = [
  &add=           [ {|stem| MOD-UNTRACKED; UNMERGED; comp:dirs $stem } ... ]
  &stage=         add
  &checkout=      [ { MODIFIED; BRANCHES } ... ]
  &switch=        [ { $BRANCHES~ &branch=$false; REMOTE-BRANCHES } ]
  &mv=            [ {|stem| TRACKED; comp:dirs $stem } ... ]
  &rm=            [ {|stem| TRACKED; comp:dirs $stem } ... ]
  &diff=          [ { MODIFIED; BRANCHES  } ... ]
  &push=          [ $REMOTES~ $BRANCHES~ ]
  &pull=          [ $REMOTES~ { BRANCHES &all } ]
  &merge=         [ $BRANCHES~ ... ]
  &init=          [ {|stem| put "."; comp:dirs $stem } ]
  &branch=        [ $BRANCHES~ ... ]
  &rebase=        [ { $BRANCHES~ &all } ... ]
  &cherry=        [ { $BRANCHES~ &all } $BRANCHES~ $BRANCHES~ ]
  &cherry-pick=   [ { $BRANCHES~ &all } ... ]
  &stash=         [
    &list= (comp:sequence [])
    &clear= (comp:sequence [])
    &show= (comp:sequence [ $STASHES~ ])
    &drop= (comp:sequence &opts=[[&short=q &long=quiet]] [ $STASHES~ ])
    &pop=   (comp:sequence &opts=[[&short=q &long=quiet] [&long=index]] [ $STASHES~ ])
    &apply= pop
    &branch= (comp:sequence [ [] $STASHES~ ])
    &push= (comp:sequence [ $comp:files~ ... ] &opts=[
        [&short=p &long=patch]
        [&short=k &long=keep-index] [&long=no-keep-index]
        [&short=q &long=quiet]
        [&short=u &long=include-untracked]
        [&short=a &long=all]
        [&short=m &long=message &arg-required]
    ])
    &create= (comp:sequence [])
    &store= (comp:sequence [ $BRANCHES~ ] &opts=[
        [&short=m &long=message &arg-required]
        [&short=q &long=quiet]
    ])
  ]
]

fn init {
  set completions = [&]
  -run-git help -a --no-verbose | eawk {|line @f| if (re:match '^  [a-z]' $line) { put $@f } } | each {|c|
    var seq = [ $comp:files~ ... ]
    if (has-key $git-completions $c) {
      set seq = $git-completions[$c]
    }
    if (eq (kind-of $seq) string) {
      set completions[$c] = $seq
    } elif (eq (kind-of $seq) map) {
      set completions[$c] = (comp:subcommands $seq)
    } else {
      set completions[$c] = (comp:sequence $seq &opts={ -git-opts $c })
    }
  }
  -run-git config --list | each {|l| re:find '^alias\.([^=]+)=(\S+)' $l } | each {|m|
    var alias target = $m[groups][1 2][text]
    if (has-key $completions $target) {
      set completions[$alias] = $target
    } else {
      set completions[$alias] = (comp:sequence [])
    }
  }
  set git-arg-completer = (comp:subcommands $completions ^
    &pre-hook={|@_| set status = (git:status) } &opts={ -git-opts }
  )
  set edit:completion:arg-completer[git] = $git-arg-completer
}

init
