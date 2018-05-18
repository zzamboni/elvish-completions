use ./comp
dir-style = 'blue;bold'
completions = [
  &-seq= [
    [arg]{ comp:files $arg &dirs-only | comp:decorate &style=$dir-style }
    $nop~
  ]
]

edit:completion:arg-completer[cd] = [@cmd]{
  comp:expand $completions $@cmd
}
