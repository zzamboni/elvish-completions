use ./comp
completions = [
  [arg]{ put {$arg}*[match-hidden][nomatch-ok] | each [x]{
      if (-is-dir $x) {
        edit:complex-candidate &code-suffix=/ &style='blue;bold' $x
      }
    }
  }
  { comp:empty }
]

edit:completion:arg-completer[cd] = [@cmd]{
  comp:sequence $completions $@cmd
}
