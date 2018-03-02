# Completion for git (or tools which allow git commands to be passed, like vcsh)
# Diego Zamboni <diego@zzamboni.org>
# Some code from https://github.com/occivink/config/blob/master/.elvish/rc.elv

# Fetch list of valid git commands and aliases from git itself
-cmds = [
  (git help -a | grep '^  [a-z]' | tr -s "[:blank:]" "\n" | each [x]{ if (> (count $x) 0) { put $x } })
  (err = ?(git config --list | grep alias | sed 's/^alias\.//; s/=.*$//'))
]
commands = [(echo &sep="\n" $@-cmds | sort)]

# This allows $gitcmd to be a multi-word command and still be executed
# correctly. We cannot simply run "$gitcmd <opts>" because Elvish always
# interprets the first token (the head) to be the command.
# One example of a multi-word $gitcmd is "vcsh <repo>", after which
# any git subcommand is valid.
fn -run-git-cmd [gitcmd @rest]{
  gitcmds = [$gitcmd]
  if (eq (kind-of $gitcmd) string) {
    gitcmds = [(splits " " $gitcmd)]
  }
  cmd = $gitcmds[0]
  if (eq (kind-of $cmd) string) {
    cmd = (external $cmd)
  }
  if (> (count $gitcmds) 1) {
    $cmd (explode $gitcmds[1:]) $@rest
  } else {
    $cmd $@rest
  }
}

fn git-completer [gitcmd @rest]{
  n = (count $rest)
  if (eq $n 1) {
    put $@commands
  } else {
    # From https://github.com/occivink/config/blob/master/.elvish/rc.elv
    subcommand = $rest[0]
    if (or (eq $subcommand add) (eq $subcommand stage)) {
      -run-git-cmd $gitcmd diff --name-only
      -run-git-cmd $gitcmd ls-files --others --exclude-standard
    } elif (or (eq $subcommand checkout) (eq $subcommand co)) {
      -run-git-cmd $gitcmd branch --list --all --format '%(refname:short)'
      -run-git-cmd $gitcmd diff --name-only
    } elif (or (eq $subcommand mv) (eq $subcommand rm) (eq $subcommand diff)) {
      -run-git-cmd $gitcmd ls-files
    }
  }
}

edit:completion:arg-completer[git] = $git-completer~
