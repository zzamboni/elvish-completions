use ./comp
use re

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

-ssh-options = [(
    _ = ?(cat (man -w ssh_config 2>/dev/null)) |
    eawk [l @f]{ if (re:match '^\.It Cm' $l) { put $f[2] } } |
    comp:decorate &suffix='='
)]

ssh-opts = [ [ &short= o ] ]

fn -gen-ssh-completions [&suffix='']{
  put [ [@cmd]{
      if (eq $cmd[-2] "-o") {
        explode $-ssh-options
      } else {
        -ssh-hosts | comp:decorate &suffix=$suffix
      }
  } ... ]
}

edit:completion:arg-completer[ssh]  = (comp:sequence &opts=$ssh-opts (-gen-ssh-completions))
edit:completion:arg-completer[sftp] = (comp:sequence &opts=$ssh-opts (-gen-ssh-completions))
edit:completion:arg-completer[scp]  = (comp:sequence &opts=$ssh-opts (-gen-ssh-completions &suffix=":"))
