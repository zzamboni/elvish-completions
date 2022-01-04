use re
use str
use path

var debug = $false

fn -debugmsg {|@args &color=blue|
  if $debug {
    echo (styled (echo ">>> " $@args) $color) >/dev/tty
  }
}

fn decorate {|@input &code-suffix='' &display-suffix='' &suffix='' &style=$nil |
  if (== (count $input) 0) {
    set input = [(all)]
  }
  if (not-eq $suffix '') {
    set display-suffix = $suffix
    set code-suffix = $suffix
  }
  each {|k|
    var k-display = $k
    if $style {
      set k-display = (styled $k $style)
    }
    edit:complex-candidate &code-suffix=$code-suffix &display=$k-display$display-suffix $k
  } $input
}

fn empty { nop }

fn files {|arg &regex='' &dirs-only=$false &transform=$nil|
  edit:complete-filename $arg | each {|c|
    var x = $c[stem]
    if (or (path:is-dir $x) (and (not $dirs-only) (or (eq $regex '') (re:match $regex $x)))) {
      if $transform {
        edit:complex-candidate ($transform $x)
      } else {
        put $c
      }
    }
  }
}

fn dirs {|arg &regex='' &transform=$nil|
  files $arg &regex=$regex &dirs-only=$true &transform=$transform
}

fn extract-opts {|@cmd
  &regex='^\s*(?:-(\w),?\s*)?(?:--?([\w-]+))?(?:\[=(\S+)\]|[ =](\S+))?\s*?\s\s(\w.*)$'
  &regex-map=[&short=1 &long=2 &arg-optional=3 &arg-required=4 &desc=5]
  &fold=$false
  &first-sentence=$false
  &opt-completers=[&]
|
  var -line = ''
  var capture = $all~
  if $fold {
    set capture = { each {|l|
        if (re:match '^\s{8,}\w' $l) {
          var folded = $-line$l
          # -debugmsg "Folded line: "$folded
          put $folded
          set -line = ''
        } else {
          # -debugmsg "Non-folded line: "$-line
          put $-line
          set -line = $l
        }
      }
    }
  }
  $capture | each {|l|
    -debugmsg "Got line: "$l
    re:find $regex $l
  } | each {|m|
    -debugmsg "Matches: "(to-string $m) &color=red
    var g = $m[groups]
    var opt = [&]
    keys $regex-map | each {|k|
      if (has-key $g $regex-map[$k]) {
        var field = (str:trim-space $g[$regex-map[$k]][text])
        if (not-eq $field '') {
          if (has-value [arg-optional arg-required] $k) {
            set opt[$k] = $true
            set opt[arg-desc] = $field
            if (has-key $opt-completers $field) {
              set opt[arg-completer] = $opt-completers[$field]
            } else {
              set opt[arg-completer] = $edit:complete-filename~
            }
          } else {
            set opt[$k] = $field
          }
        }
      }
    }
    if (or (has-key $opt short) (has-key $opt long)) {
      if (has-key $opt desc) {
        if $first-sentence {
          set opt[desc] = (re:replace '\. .*$|\.\s*$|\s*\(.*$' '' $opt[desc])
        } 
        set opt[desc] = (re:replace '\s+' ' ' $opt[desc])
      }
      put $opt
    }
  }
}

fn -handler-arity {|func|
  var fnargs = [ (to-string (count $func[arg-names])) (== $func[rest-arg] -1)]
  if     (eq $fnargs [ 0 $true ])  { put no-args
  } elif (eq $fnargs [ 1 $true ])  { put one-arg
  } elif (eq $fnargs [ 1 $false ]) { put rest-arg
  } else {                           put other-args
  }
}

fn -expand-item {|def @cmd|
  var arg = $cmd[-1]
  var what = (kind-of $def)
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

fn -expand-sequence {|seq @cmd &opts=[]|

var final-opts = [(
    -expand-item $opts $@cmd | each {|opt|
      -debugmsg "In final-opts: opt before="(to-string $opt) &color=yellow
      if (eq (kind-of $opt) map) {
        if (has-key $opt arg-completer) {
          -debugmsg &color=yellow "Assigning opt[completer] = [_]{ -expand-item "(to-string $opt[arg-completer]) $@cmd "}" 
          set opt[completer] = {|_| -expand-item $opt[arg-completer] $@cmd }
        }
        -debugmsg "In final-opts: opt after="(to-string $opt) &color=yellow
        put $opt
      } else {
        put [&long= $opt]
      }
    }
)]

var final-handlers = [(
    all $seq | each {|f|
      if (eq (kind-of $f) 'fn') {
        put [
          &no-args=  {|_| $f }
          &one-arg=  $f
          &rest-arg= {|_| $f $@cmd }
          &other-args= {|_| put '<expand-sequence-completion-fn-arity-error>' }
        ][(-handler-arity $f)]
      } elif (eq (kind-of $f) 'list') {
        put {|_| all $f }
      } elif (and (eq (kind-of $f) 'string') (eq $f '...')) {
        put $f
      }
    }
)]

-debugmsg Calling: edit:complete-getopt (to-string $cmd[1..]) (to-string $final-opts) (to-string $final-handlers)
edit:complete-getopt $cmd[1..] $final-opts $final-handlers
}

fn -expand-subcommands {|def @cmd &opts=[]|

var subcommands = [(keys $def)]
var n = (count $cmd)
var kw = [(range 1 $n | each {|i|
      if (has-value $subcommands $cmd[$i]) { put $cmd[$i] $i }
})]

if (and (not-eq $kw []) (not-eq $kw[1] (- $n 1))) {
  var sc sc-pos = $kw[0 1]
  if (eq (kind-of $def[$sc]) 'string') {
    set cmd[$sc-pos] = $def[$sc]
    -expand-subcommands &opts=$opts $def $@cmd
  } else {
    $def[$sc] (all $cmd[{$sc-pos}..])
  }

} else {
    var top-def = [ { put $@subcommands } ]
    -expand-sequence &opts=$opts $top-def $@cmd
  }
}

fn item {|item &pre-hook=$nop~ &post-hook=$nop~|
  put {|@cmd|
    $pre-hook $@cmd
    var result = [(-expand-item $item $@cmd)]
    $post-hook $result $@cmd
    put $@result
  }
}

fn sequence {|sequence &opts=[] &pre-hook=$nop~ &post-hook=$nop~|
  put {|@cmd &inspect=$false|
    if $inspect {
      echo "comp:sequence definition: "(to-string $sequence)
      echo "opts: "(to-string $opts)
    } else {
      $pre-hook $@cmd
      var result = [(-expand-sequence &opts=$opts $sequence $@cmd)]
      $post-hook $result $@cmd
      put $@result
    }
  }
}

fn subcommands {|def &opts=[] &pre-hook=$nop~ &post-hook=$nop~|
  put {|@cmd &inspect=$false|
    if $inspect {
      echo "Completer definition: "(to-string $def)
      echo "opts: "(to-string $opts)
    } else {
      $pre-hook $@cmd
      if (and (eq $opts []) (has-key $def -options)) {
        set opts = $def[-options]
      }
      del def[-options]
      var result = [(-expand-subcommands &opts=$opts $def $@cmd)]
      $post-hook $result $@cmd
      put $@result
    }
  }
}
