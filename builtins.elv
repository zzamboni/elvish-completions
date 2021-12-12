use ./comp
use re
use path
use str

set edit:completion:arg-completer[use] = (
  comp:sequence [
    {|stem|
      if (not (str:has-prefix $stem '.')) {
        put './' '../'
        put ~/.elvish/lib/**[nomatch-ok].elv | each {|m|
          if (not (path:is-dir $m)) {
            re:replace ~/.elvish/lib/'(.*).elv' '$1' $m
          }
        }
      } else {
        if (eq $stem ".") { set stem = "./" }
        if (eq $stem "..") { set stem = "../" }
        comp:files $stem &regex='.*\.elv' &transform={|s| re:replace '\.elv$' '' $s }
      }
    }
  ]
)

use epm

var epm-completer-one  = (comp:sequence [ $epm:list~ ])
var epm-completer-many = (comp:sequence [ $epm:list~ ...])
set edit:completion:arg-completer[epm:query]     = $epm-completer-one
set edit:completion:arg-completer[epm:metadata]  = $epm-completer-one
set edit:completion:arg-completer[epm:dest]      = $epm-completer-one
set edit:completion:arg-completer[epm:uninstall] = $epm-completer-many
set edit:completion:arg-completer[epm:upgrade]   = $epm-completer-many

set edit:completion:arg-completer[elvish] = (comp:sequence ^
  &opts= { elvish -help | comp:extract-opts &fold } ^
  [ {|arg| comp:files $arg &regex='\.elv$' } ] ^
)
