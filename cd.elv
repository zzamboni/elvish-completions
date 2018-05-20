use ./comp

dir-style = 'blue;bold'

completions = [
  &-seq= [
    [stem]{ comp:files $stem &dirs-only | comp:decorate &style=$dir-style &code-suffix=/ }
  ]
]

edit:completion:arg-completer[cd] = (comp:expand-wrapper $completions)
