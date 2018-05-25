use ./comp
use re

edit:completion:arg-completer[use] = (comp:sequence {
    put ~/.elvish/lib/**[nomatch-ok].elv | each [m]{
      if (not (-is-dir $m)) {
        re:replace ~/.elvish/lib/'(.*).elv' '$1' $m
      }
    }
  }
)
