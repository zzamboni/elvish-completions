use ./comp
use re

config-files = [ ~/.ssh/config /etc/ssh/ssh_config /etc/ssh_config ]

fn -ssh-hosts {
  hosts = [&]
  explode $config-files | each [file]{
    _ = ?(cat $file 2>&-) | eawk [_ @f]{
      if (re:match '^(?i)host$' $f[0]) {
        explode $f[1:] | each [p]{
          if (not (re:match '[*?!]' $p)) {
            hosts[$p] = $true
  }}}}}
  keys $hosts
}

-ssh-options = []
fn -gen-ssh-options {
  if (eq $-ssh-options []) {
    -ssh-options = [(
        _ = ?(cat (man -w ssh_config 2>&-)) |
        eawk [l @f]{ if (re:match '^\.It Cm' $l) { put $f[2] } } |
        comp:decorate &suffix='='
    )]
  }
  explode $-ssh-options
}

ssh-opts = [
  [ &short= o
    &arg-required= $true
    &arg-completer= $-gen-ssh-options~
  ]
  [ &short= i
    &long= inventory
    &arg-required= $true
    &arg-completer= $comp:files~
  ]
]

fn -ssh-host-completions [arg &suffix='']{
  user-given = (joins '' [(re:find '^(.*@)' $arg)[groups][1][text]])
  -ssh-hosts | each [host]{ put $user-given$host } | comp:decorate &suffix=$suffix
}

edit:completion:arg-completer[ssh]  = (comp:sequence &opts=$ssh-opts [$-ssh-host-completions~])
edit:completion:arg-completer[sftp] = (comp:sequence &opts=$ssh-opts [$-ssh-host-completions~])
edit:completion:arg-completer[scp]  = (comp:sequence &opts=$ssh-opts [
    [arg]{
      -ssh-host-completions &suffix=":" $arg
      edit:complete-filename $arg
    }
    ...
])
