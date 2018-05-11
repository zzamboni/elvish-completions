use ./comp
use re

completions = []

config-files = [ ~/.ssh/config /etc/ssh/ssh_config /etc/ssh_config ]

fn -ssh-hosts {
  hosts = [&]
  explode $config-files | each [file]{
    _ = ?(cat $file 2>/dev/null) | eawk [_ @f]{
      if (re:match '^(?i)host$' $f[0]) {
        explode $f[1:] | each [p]{
          if (not (re:match '[*?!]' $p)) {
            hosts[$p] = $true
  }}}}}
  keys $hosts
}

fn -ssh-options {
  _ = ?(cat (man -w ssh_config 2>/dev/null)) | eawk [l @f]{ if (re:match '^\.It Cm' $l) { put $f[2] } }
}

completions = [ { -ssh-hosts; put '-o' } ]

fn ssh-completer [@cmd]{
  if (eq $cmd[-2] "-o") {
    -ssh-options | each [opt]{
      edit:complex-candidate &code-suffix='=' &display-suffix='=' $opt
    }
  } else {
    comp:sequence $completions $@cmd
  }
}

edit:completion:arg-completer[ssh] = $ssh-completer~
