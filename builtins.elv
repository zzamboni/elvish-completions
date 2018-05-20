use ./comp
use re

use-completer = [
  &-seq= [
    { put ~/.elvish/lib/**[nomatch-ok].elv | each [m]{
        if (not (-is-dir $m)) {
          re:replace ~/.elvish/lib/'(.*).elv' '$1' $m
        }
      }
    }
  ]
]

edit:completion:arg-completer[use] = (comp:expand-wrapper $use-completer)
