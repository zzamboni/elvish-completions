use ./comp

dir-style = 'blue;bold'

edit:completion:arg-completer[cd] = (comp:sequence [[stem]{
    comp:files $stem &dirs-only | comp:decorate &style=$dir-style &code-suffix=/
  }])
