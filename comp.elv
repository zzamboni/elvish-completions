use re
use github.com/zzamboni/elvish-modules/util

fn decorate [&code-suffix='' &display-suffix='' &suffix='' &style='' @input]{
  if (eq (count $input) 0) {
    input = [(all)]
  }
  if (not-eq $suffix '') {
    display-suffix = $suffix
    code-suffix = $suffix
  }
  each [k]{
    edit:complex-candidate &code-suffix=$code-suffix &display-suffix=$display-suffix &style=$style $k
  } $input
}

fn empty { nop }

fn files [arg &regex='' &dirs-only=$false]{
  put {$arg}*[match-hidden][nomatch-ok] | each [x]{
    if (and (or (not $dirs-only) (-is-dir $x)) (or (eq $regex '') (re:match $regex $x))) {
      put $x
    }
  }
}

# Forward declarations to be overriden later
fn sequence { }
fn subcommands { }

fn expand [def @cmd]{
  arg = $cmd[-1]
  what = (kind-of $def)
  if (eq $what 'fn') {
    $def $arg
  } elif (eq $what 'list') {
    explode $def
  } elif (eq $what 'map') {
    if (has-key $def '-seq') {
      sequence $def $@cmd
    } else {
      subcommands $def $@cmd
    }
  }
}

sequence~ = [def @cmd]{
  opts = []
  if (has-key $def -opts) {
    expand $def[-opts] $@cmd | each [opt]{
      if (eq (kind-of $opt) map) {
        opts = [ $@opts $opt ]
      } else {
        opts = [$@opts [&long= $opt]]
      }
    }
  }
  edit:complete-getopt $cmd[1:] $opts [(explode $def[-seq])]
}

subcommands~ = [def @cmd]{
  n = (count $cmd)

if (eq $n 2) {
  keys (dissoc $def -opts)
  if (has-key $def -opts) {
    expand $def[-opts] $@cmd
  }

} else {
    subcommand = $cmd[1]
    if (has-key $def $subcommand) {
      if (eq (kind-of $def[$subcommand]) 'string') {
        subcommands $def $cmd[0] $def[$subcommand] (explode $cmd[2:])
      } else {
        expand $def[$subcommand] (explode $cmd[1:])
      }
    }
  }
}

fn -wrapper-gen [func]{
  put [def]{ put [@cmd]{ $func $def $@cmd } }
}

expand-wrapper~ = (-wrapper-gen $expand~)
sequence-wrapper~ = (-wrapper-gen $sequence~)
subcommands-wrapper~ = (-wrapper-gen $subcommands~)
