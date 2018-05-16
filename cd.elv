use ./comp
completions = [
  &-seq= [
    [arg]{ put {$arg}*[match-hidden][nomatch-ok] | each [x]{
        if (-is-dir $x) {
          edit:complex-candidate &code-suffix=/ &style='blue;bold' $x
        }
      }
    }
    $nop~
  ]
]

edit:completion:arg-completer[cd] = [@cmd]{
  comp:expand $completions $@cmd
}
