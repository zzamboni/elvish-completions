use re
use github.com/zzamboni/elvish-modules/util

fn decorate [@input &code-suffix='' &display-suffix='' &suffix='' &style='']{
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

fn extract-opts [@cmd
  &regex='(?:-(\w),\s*)?--([\w-]+).*?\s\s(\w.*)$'
  &regex-map=[&short=1 &long=2 &desc=3]
]{
  all | each [l]{
  re:find $regex $l } | each [m]{
    short long desc = $m[groups][$regex-map[short long desc]][text]
    opt = [&]
    if (not-eq $short '') { opt[short] = $short }
    if (not-eq $long  '') { opt[long]  = $long  }
    if (not-eq $desc  '') { opt[desc]  = $desc  }
    if (or (has-key $opt short) (has-key $opt long)) {
      put $opt
    }
  }
}

fn -handler-arity [func]{
  fnargs = [ (count $func[arg-names]) (not-eq $func[rest-arg] '') ]
  if     (eq $fnargs [ 0 $false ]) { put no-args
  } elif (eq $fnargs [ 1 $false ]) { put one-arg
  } elif (eq $fnargs [ 0 $true  ]) { put rest-arg
  } else {                           put other-args
  }
}

fn -expand-item [def @cmd]{
  arg = $cmd[-1]
  what = (kind-of $def)
  if (eq $what 'fn') {
    [ &no-args=  { $def }
      &one-arg=  { $def $arg }
      &rest-arg= { $def $@cmd }
      &other-args= { put '<completion-fn-arity-error>' }
    ][(-handler-arity $def)]
  } elif (eq $what 'list') {
    explode $def
  } else {
    echo (edit:styled "comp:-expand-item: invalid item of type "$what": "(to-string $def) red) >/dev/tty
  }
}

fn -expand-sequence [seq @cmd &opts=[]]{

final-opts = [(
    -expand-item $opts $@cmd | each [opt]{
      if (eq (kind-of $opt) map) {
        put $opt
      } else {
        put [&long= $opt]
      }
    }
)]

fn -has-and-is [def opt]{
  or (and (has-key $def short) (eq '-'$def[short] $opt)) (and (has-key $def long) (eq '--'$def[long] $opt))
}

if (>= (count $cmd) 3) {
  prev-opt = [&]
  prev-word = $cmd[-2]
  each [o]{
    if (-has-and-is $o $prev-word) {
      prev-opt = $o
    }
  } $final-opts
  if (and (not-eq $prev-opt [&]) (has-key $prev-opt arg-completer)) {
    -expand-item $prev-opt[arg-completer] $@cmd
    if (and (has-key $prev-opt arg-required) $prev-opt[arg-required]) {
      return
    }
  }
}

final-handlers = [(
    explode $seq | each [f]{
      if (eq (kind-of $f) 'fn') {
        put [
          &no-args=  [_]{ $f }
          &one-arg=  $f
          &rest-arg= [_]{ $f $@cmd }
          &other-args= [_]{ put '<completion-fn-arity-error>' }
        ][(-handler-arity $f)]
      } elif (eq (kind-of $f) 'list') {
        put [_]{ explode $f }
      } elif (and (eq (kind-of $f) 'string') (eq $f '...')) {
        put $f
      }
    }
)]

edit:complete-getopt $cmd[1:] $final-opts $final-handlers
}

fn -expand-subcommands [def @cmd &opts=[]]{

subcommands = [(keys $def)]
n = (count $cmd)
kw = [(range 1 $n | each [i]{
      if (has-value $subcommands $cmd[$i]) { put $cmd[$i] $i }
})]

if (and (not-eq $kw []) (not-eq $kw[1] (- $n 1))) {
  sc sc-pos = $kw[0 1]
  if (eq (kind-of $def[$sc]) 'string') {
    cmd[$sc-pos] = $def[$sc]
    -expand-subcommands &opts=$opts $def $@cmd
  } else {
    $def[$sc] (explode $cmd[{$sc-pos}:])
  }

} else {
    top-def = [ { put $@subcommands } ]
    -expand-sequence &opts=$opts $top-def $@cmd
  }
}

fn item [item &pre-hook=$nop~ &post-hook=$nop~]{
  put [@cmd]{
    $pre-hook $@cmd
    result = [(-expand-item $item $@cmd)]
    $post-hook $result $@cmd
    put $@result
  }
}

fn sequence [sequence &opts=[] &pre-hook=$nop~ &post-hook=$nop~]{
  put [@cmd]{
    $pre-hook $@cmd
    result = [(-expand-sequence &opts=$opts $sequence $@cmd)]
    $post-hook $result $@cmd
    put $@result
  }
}

fn subcommands [def &opts=[] &pre-hook=$nop~ &post-hook=$nop~]{
  put [@cmd]{
    $pre-hook $@cmd
    result = [(-expand-subcommands &opts=$opts $def $@cmd)]
    $post-hook $result $@cmd
    put $@result
  }
}
