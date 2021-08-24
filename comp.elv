use re
use str
use path

debug = $false

fn -debugmsg [@args &color=blue]{
  if $debug {
    echo (styled (echo ">>> " $@args) $color) >/dev/tty
  }
}

fn decorate [@input &code-suffix='' &display-suffix='' &suffix='' &style='']{
  # &style is currently ignored because it is not supported by Elvish
  if (== (count $input) 0) {
    input = [(all)]
  }
  if (not-eq $suffix '') {
    display-suffix = $suffix
    code-suffix = $suffix
  }
  each [k]{
    edit:complex-candidate &code-suffix=$code-suffix &display=$k$display-suffix $k
  } $input
}

fn empty { nop }

fn files [arg &regex='' &dirs-only=$false &transform=$nil]{
  edit:complete-filename $arg | each [c]{
    x = $c[stem]
    if (or (path:is-dir $x) (and (not $dirs-only) (or (eq $regex '') (re:match $regex $x)))) {
      if $transform {
        edit:complex-candidate ($transform $x)
      } else {
        put $c
      }
    }
  }
}

fn dirs [arg &regex='' &transform=$nil]{
  files $arg &regex=$regex &dirs-only=$true &transform=$transform
}

fn extract-opts [@cmd
  &regex='^\s*(?:-(\w),?\s*)?(?:--?([\w-]+))?(?:\[=(\S+)\]|[ =](\S+))?\s*?\s\s(\w.*)$'
  &regex-map=[&short=1 &long=2 &arg-optional=3 &arg-required=4 &desc=5]
  &fold=$false
  &first-sentence=$false
  &opt-completers=[&]
]{
  -line = ''
  capture = $all~
  if $fold {
    capture = { each [l]{
        if (re:match '^\s{8,}\w' $l) {
          var folded = $-line$l
          # -debugmsg "Folded line: "$folded
          put $folded
          -line = ''
        } else {
          # -debugmsg "Non-folded line: "$-line
          put $-line
          -line = $l
        }
      }
    }
  }
  $capture | each [l]{
    -debugmsg "Got line: "$l
    re:find $regex $l
  } | each [m]{
    -debugmsg "Matches: "(to-string $m) &color=red
    g = $m[groups]
    opt = [&]
    keys $regex-map | each [k]{
      if (has-key $g $regex-map[$k]) {
        field = (str:trim-space $g[$regex-map[$k]][text])
        if (not-eq $field '') {
          if (has-value [arg-optional arg-required] $k) {
            opt[$k] = $true
            opt[arg-desc] = $field
            if (has-key $opt-completers $field) {
              opt[arg-completer] = $opt-completers[$field]
            } else {
              opt[arg-completer] = $edit:complete-filename~
            }
          } else {
            opt[$k] = $field
          }
        }
      }
    }
    if (or (has-key $opt short) (has-key $opt long)) {
      if (has-key $opt desc) {
        if $first-sentence {
          opt[desc] = (re:replace '\. .*$|\.\s*$|\s*\(.*$' '' $opt[desc])
        } 
        opt[desc] = (re:replace '\s+' ' ' $opt[desc])
      }
      put $opt
    }
  }
}

fn -handler-arity [func]{
  fnargs = [ (to-string (count $func[arg-names])) (== $func[rest-arg] -1)]
  if     (eq $fnargs [ 0 $true ])  { put no-args
  } elif (eq $fnargs [ 1 $true ])  { put one-arg
  } elif (eq $fnargs [ 1 $false ]) { put rest-arg
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
      &other-args= { put '<expand-item-completion-fn-arity-error>' }
    ][(-handler-arity $def)]
  } elif (eq $what 'list') {
    all $def
  } else {
    echo (styled "comp:-expand-item: invalid item of type "$what": "(to-string $def) red) >/dev/tty
  }
}

fn -expand-sequence [seq @cmd &opts=[]]{

final-opts = [(
    -expand-item $opts $@cmd | each [opt]{
      -debugmsg "In final-opts: opt before="(to-string $opt) &color=yellow
      if (eq (kind-of $opt) map) {
        if (has-key $opt arg-completer) {
          -debugmsg &color=yellow "Assigning opt[completer] = [_]{ -expand-item "(to-string $opt[arg-completer]) $@cmd "}" 
          opt[completer] = [_]{ -expand-item $opt[arg-completer] $@cmd }
        }
        -debugmsg "In final-opts: opt after="(to-string $opt) &color=yellow
        put $opt
      } else {
        put [&long= $opt]
      }
    }
)]

final-handlers = [(
    all $seq | each [f]{
      if (eq (kind-of $f) 'fn') {
        put [
          &no-args=  [_]{ $f }
          &one-arg=  $f
          &rest-arg= [_]{ $f $@cmd }
          &other-args= [_]{ put '<expand-sequence-completion-fn-arity-error>' }
        ][(-handler-arity $f)]
      } elif (eq (kind-of $f) 'list') {
        put [_]{ all $f }
      } elif (and (eq (kind-of $f) 'string') (eq $f '...')) {
        put $f
      }
    }
)]

-debugmsg Calling: edit:complete-getopt (to-string $cmd[1..]) (to-string $final-opts) (to-string $final-handlers)
edit:complete-getopt $cmd[1..] $final-opts $final-handlers
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
    $def[$sc] (all $cmd[{$sc-pos}..])
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
  put [@cmd &inspect=$false]{
    if $inspect {
      echo "comp:sequence definition: "(to-string $sequence)
      echo "opts: "(to-string $opts)
    } else {
      $pre-hook $@cmd
      result = [(-expand-sequence &opts=$opts $sequence $@cmd)]
      $post-hook $result $@cmd
      put $@result
    }
  }
}

fn subcommands [def &opts=[] &pre-hook=$nop~ &post-hook=$nop~]{
  put [@cmd &inspect=$false]{
    if $inspect {
      echo "Completer definition: "(to-string $def)
      echo "opts: "(to-string $opts)
    } else {
      $pre-hook $@cmd
      if (and (eq $opts []) (has-key $def -options)) {
        opts = $def[-options]
      }
      del def[-options]
      result = [(-expand-subcommands &opts=$opts $def $@cmd)]
      $post-hook $result $@cmd
      put $@result
    }
  }
}
