use ./comp
use re
use str

var config-files = [ ~/.ssh/config /etc/ssh/ssh_config /etc/ssh_config ]

fn -ssh-hosts {
  var hosts = [&]
  all $config-files | each {|file|
    set _ = ?(cat $file 2>&-) | re:awk {|_ @f|
      if (re:match '^(?i)host$' $f[0]) {
        all $f[1..] | each {|p|
          if (not (re:match '[*?!]' $p)) {
            set hosts[$p] = $true
  }}}}}
  keys $hosts
}

var -ssh-options = []
fn -gen-ssh-options {
  if (eq $-ssh-options []) {
    set -ssh-options = [(
        set _ = ?(cat (man -w ssh_config 2>&-)) |
        re:awk {|l @f| if (re:match '^\.It Cm' $l) { put $f[2] } } |
        comp:decorate &suffix='='
    )]
  }
  all $-ssh-options
}

var ssh-opts = [
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

fn -ssh-host-completions {|arg &suffix=''|
  var user-given = (str:join '' [(re:find '^(.*@)' $arg)[groups][1][text]])
  -ssh-hosts | each {|host| put $user-given$host } | comp:decorate &suffix=$suffix
}

set edit:completion:arg-completer[ssh]  = (comp:sequence &opts=$ssh-opts [$-ssh-host-completions~])
set edit:completion:arg-completer[sftp] = (comp:sequence &opts=$ssh-opts [$-ssh-host-completions~])
set edit:completion:arg-completer[scp]  = (comp:sequence &opts=$ssh-opts [
    {|arg|
      -ssh-host-completions &suffix=":" $arg
      edit:complete-filename $arg
    }
    ...
])
