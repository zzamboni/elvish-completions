use ./comp

set edit:completion:arg-completer[cd] = (comp:sequence [ {|stem|
      comp:files $stem &dirs-only
}])
