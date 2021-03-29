use ./comp
use str

-complete-dev = {
  evdev-dir = '/dev/input/'
  ls $evdev-dir | each [item]{
    if (str:has-prefix $item 'event') {
      path = $evdev-dir$item
      name = (cat /sys/class/input/$item/device/name)
      edit:complex-candidate &display=$path" ("$name")" $path
    }
  }
}

ev-code-header = /usr/include/linux/input-event-codes.h

fn -defs-with-prefix [prefix]{
  grep "#define "$prefix"_" $ev-code-header |
      eawk [line @fields]{ put $fields[1] }
}

fn -ev-codes-for-type [type]{
  if (eq $type 'EV_KEY') {
    -defs-with-prefix 'KEY'
    -defs-with-prefix 'BTN'
  } else {
    -defs-with-prefix (str:trim-prefix $type 'EV_')
  }
}

-evtest-opts = [
  [&long="grab"  &desc="grab the device for exclusive access"]
  [&long="query" &desc="query a specific single-bit event code"]
]

-complete-evtest-type = [@cmd]{
  if (eq $cmd[1] '--query') {
    all [EV_KEY EV_SW EV_SND EV_LED]
  }
}

-complete-evtest-code = [@cmd]{
  if (eq $cmd[1] '--query') {
    -ev-codes-for-type $cmd[3]
  }
}

edit:completion:arg-completer[evtest] = (
    comp:sequence &opts=$-evtest-opts [$-complete-dev $-complete-evtest-type $-complete-evtest-code])

-autorestart-opt = [
  &long="autorestart"
  &desc="Terminate the current recording after <s> seconds of inactivity and restart a new recording"
  &arg-required=$true
]

-record-and-describe-comp = (comp:sequence &opts=[$-autorestart-opt] [$-complete-dev $comp:files~])
edit:completion:arg-completer[evemu-describe] = $-record-and-describe-comp
edit:completion:arg-completer[evemu-record] = $-record-and-describe-comp

edit:completion:arg-completer[evemu-device] = $edit:complete-filename~

edit:completion:arg-completer[evemu-play] = (comp:sequence [[arg]{
  $-complete-dev
  comp:files $arg
}])

-all-ev-codes = {
  prefix-pattern = (-defs-with-prefix 'EV' | each [s]{ str:trim-prefix $s 'EV_' } | str:join '\|')
  -defs-with-prefix '\('$prefix-pattern'\|BTN\)'
}

-event-opts = [
  [&long="sync" &desc="generate an EV_SYN event after the event"]
  [&long="type"
   &desc="the type of event to generate"
   &arg-required=$true
   &arg-completer={ -defs-with-prefix 'EV' }]
  [&long="code"
   &desc="the event code"
   &arg-required=$true
   &arg-completer=$-all-ev-codes]
  [&long="value"
   &desc="the event value"
   &arg-required=$true]
]

edit:completion:arg-completer[evemu-event] = (comp:sequence &opts=$-event-opts [$-complete-dev])
