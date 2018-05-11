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

completions = [ { -ssh-hosts } ]

fn ssh-completer [@cmd]{
  comp:sequence $completions $@cmd
}

edit:completion:arg-completer[ssh] = $ssh-completer~
