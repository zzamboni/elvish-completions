use ./comp
use str

var -complete-dev = {
  var evdev-dir = '/dev/input/'
  ls $evdev-dir | each {|item|
    if (str:has-prefix $item 'event') {
      var path = $evdev-dir$item
      var name = (cat /sys/class/input/$item/device/name)
      edit:complex-candidate &display=$path" ("$name")" $path
    }
  }
}

var ev-code-header = /usr/include/linux/input-event-codes.h

fn -defs-with-prefix {|prefix|
  grep "#define "$prefix"_" $ev-code-header |
      eawk {|line @fields| put $fields[1] }
}

fn -ev-codes-for-type {|type|
  if (eq $type 'EV_KEY') {
    -defs-with-prefix 'KEY'
    -defs-with-prefix 'BTN'
  } else {
    -defs-with-prefix (str:trim-prefix $type 'EV_')
  }
}

var -evtest-opts = [
  [&long="grab"  &desc="grab the device for exclusive access"]
  [&long="query" &desc="query a specific single-bit event code"]
]

var -complete-evtest-type = {|@cmd|
  if (eq $cmd[1] '--query') {
    all [EV_KEY EV_SW EV_SND EV_LED]
  }
}

var -complete-evtest-code = {|@cmd|
  if (eq $cmd[1] '--query') {
    -ev-codes-for-type $cmd[3]
  }
}

set edit:completion:arg-completer[evtest] = (
    comp:sequence &opts=$-evtest-opts [$-complete-dev $-complete-evtest-type $-complete-evtest-code])

var -autorestart-opt = [
  &long="autorestart"
  &desc="Terminate the current recording after <s> seconds of inactivity and restart a new recording"
  &arg-required=$true
]

var -record-and-describe-comp = (comp:sequence &opts=[$-autorestart-opt] [$-complete-dev $comp:files~])
set edit:completion:arg-completer[evemu-describe] = $-record-and-describe-comp
set edit:completion:arg-completer[evemu-record] = $-record-and-describe-comp

set edit:completion:arg-completer[evemu-device] = $edit:complete-filename~

set edit:completion:arg-completer[evemu-play] = (comp:sequence [{|arg|
  $-complete-dev
  comp:files $arg
}])

var -all-ev-codes = {
  var prefix-pattern = (-defs-with-prefix 'EV' | each {|s| str:trim-prefix $s 'EV_' } | str:join '\|')
  -defs-with-prefix '\('$prefix-pattern'\|BTN\)'
}

var -event-opts = [
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

set edit:completion:arg-completer[evemu-event] = (comp:sequence &opts=$-event-opts [$-complete-dev])
