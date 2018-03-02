edit:completion:arg-completer[cd] = [@cmd]{
  if (> (count $cmd) 2) {
    return
  }
  put $cmd[1]*[match-hidden][nomatch-ok] | each [x]{
    if (-is-dir $x) {
      edit:complex-candidate &code-suffix=/ &style='blue;bold' $x
    }
  }
}
