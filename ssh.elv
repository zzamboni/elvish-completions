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

completions-ssh = [ { -ssh-hosts; put '-o' } ]

completions-scp = [ { -ssh-hosts | comp:decorate &suffix=':'; put '-o' } ]

fn ssh-completer [def @cmd]{
  if (eq $cmd[-2] "-o") {
    -ssh-options | comp:decorate &suffix='='
  } else {
    comp:sequence $def $@cmd
  }
}

edit:completion:arg-completer[ssh]  = [@cmd]{ ssh-completer $completions-ssh $@cmd }
edit:completion:arg-completer[sftp] = [@cmd]{ ssh-completer $completions-ssh $@cmd }
edit:completion:arg-completer[scp]  = [@cmd]{ ssh-completer $completions-scp $@cmd }
