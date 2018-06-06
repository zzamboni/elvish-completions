use ./comp
use re

edit:completion:arg-completer[use] = (comp:sequence [{
    put ~/.elvish/lib/**[nomatch-ok].elv | each [m]{
      if (not (-is-dir $m)) {
        re:replace ~/.elvish/lib/'(.*).elv' '$1' $m
      }
    }
  }]
)

use epm

epm-completer-one  = (comp:sequence [ $epm:list~ ])
epm-completer-many = (comp:sequence [ $epm:list~ ...])
edit:completion:arg-completer[epm:query]     = $epm-completer-one
edit:completion:arg-completer[epm:metadata]  = $epm-completer-one
edit:completion:arg-completer[epm:dest]      = $epm-completer-one
edit:completion:arg-completer[epm:uninstall] = $epm-completer-many
edit:completion:arg-completer[epm:upgrade]   = $epm-completer-many

edit:completion:arg-completer[elvish] = (comp:sequence \
  &opts= { elvish -help | comp:extract-opts &fold } \
  [ [arg]{ comp:files $arg &regex='\.elv$' } ] \
)
