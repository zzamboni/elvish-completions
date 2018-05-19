use ./comp

dir-style = 'blue;bold'

completions = [
  &-seq= [
    [arg]{ comp:files $arg &dirs-only | comp:decorate &style=$dir-style }
  ]
]

edit:completion:arg-completer[cd] = (comp:expand-wrapper $completions)
