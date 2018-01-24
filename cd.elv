edit:arg-completer[cd] = [@cmd]{
  if (> (count $cmd) 2) {
    return
  }
  prefix=
  if (== (count $cmd) 2) {
    prefix=$cmd[1]
  }
  matches=[$prefix*[nomatch-ok]]
  if (>= (count $matches) 1) {
    put (ls -p -L -d $@matches) |
    each [i]{ if (re:match '/$' $i) { put $i } } |
    each [dir]{ edit:complex-candidate $dir &style="blue;bold" }
  }
}
