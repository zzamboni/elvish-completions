use github.com/zzamboni/elvish-modules/util

fn expand-completion-item [def item]{
  if (has-key $def $item) {
    what = (kind-of $def[$item])
    if (eq $what 'fn') {
      $def[$item]
    } elif (eq $what 'list') {
      explode $def[$item]
    }
  }
}

fn subcommands [def @cmd]{
  n = (count $cmd)

if (eq $n 2) {
  keys (dissoc $def -opts)
  if (has-key $def -opts) {
    expand-completion-item $def -opts
  }

} else {
    subcommand = $cmd[1]
    if (has-key $def $subcommand) {
      if (eq (kind-of $def[$subcommand]) 'string') {
        subcommands $def $cmd[0] $def[$subcommand] (explode $cmd[2:])
      } else {
        expand-completion-item $def[$subcommand] (util:min (- $n 3) (- (count $def[$subcommand]) 1))
      }
    }
  }
}
