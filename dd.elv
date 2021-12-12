use str

fn -comma-sep-list {|options arg|
  var prefix = $arg[..(+ 1 (str:last-index $arg ','))]
  for option [(keys $options)] {
    edit:complex-candidate &display=$options[$option] $prefix$option
  }
}

var -convs = [
  &ascii=    "ascii      (from EBCDIC to ASCII)"
  &ebcdic=   "ebcdic     (from ASCII to EBCDIC)"
  &ibm=      "ibm        (from ASCII to alternate EBCDIC)"
  &block=    "block      (pad newline-terminated records with spaces to cbs-size)"
  &unblock=  "unblock    (replace trailing spaces in cbs-size records with newline)"
  &lcase=    "lcase      (change upper case to lower case)"
  &ucase=    "ucase      (change lower case to upper case)"
  &sparse=   "sparse     (try to seek rather than write all-NUL output blocks)"
  &swab=     "swab       (swap every pair of input bytes)"
  &sync=     "sync       (pad every input block with NULs to ibs-size; when used with block or unblock, pad with spaces rather than NULs)"
  &excl=     "excl       (fail if the output file already exists)"
  &nocreat=  "nocreat    (do not create the output file)"
  &notrunc=  "notrunc    (do not truncate the output file)"
  &noerror=  "noerror    (continue after read errors)"
  &fdatasync="fdatasync  (physically write output file data before finishing)"
  &fsync=    "fsync      (likewise, but also write metadata)"
]

var -flags = [
  &append=     "append       (append mode (makes sense only for output; conv=notrunc suggested))"
  &direct=     "direct       (use direct I/O for data)"
  &directory=  "directory    (fail unless a directory)"
  &dsync=      "dsync        (use synchronized I/O for data)"
  &sync=       "sync         (likewise, but also for metadata)"
  &fullblock=  "fullblock    (accumulate full blocks of input (iflag only))"
  &nonblock=   "nonblock     (use non-blocking I/O)"
  &noatime=    "noatime      (do not update access time)"
  &nocache=    "nocache      (Request to drop cache.  See also oflag=sync)"
  &noctty=     "noctty       (do not assign controlling terminal from file)"
  &nofollow=   "nofollow     (do not follow symlinks)"
  &count_bytes="count_bytes  (treat 'count=N' as a byte count (iflag only))"
  &skip_bytes= "skip_bytes   (treat 'skip=N' as a byte count (iflag only))"
  &seek_bytes= "seek_bytes   (treat 'seek=N' as a byte count (oflag only))"
]

var -operands = [
  &bs=    [&desc="read and write up to BYTES bytes at a time (default: 512); overrides ibs and obs"]
  &cbs=   [&desc="convert BYTES bytes at a time"]
  &conv=  [&desc="convert the file as per the comma separated symbol list"
           &comp={|arg| -comma-sep-list $-convs $arg }]
  &count= [&desc="copy only N input blocks"]
  &ibs=   [&desc="read up to BYTES bytes at a time (default: 512)"]
  &if=    [&desc="read from FILE instead of stdin"
           &comp=$edit:complete-filename~]
  &iflag= [&desc="read as per the comma separated symbol list"
           &comp={|arg| -comma-sep-list $-flags $arg }]
  &obs=   [&desc="write BYTES bytes at a time (default: 512)"]
  &of=    [&desc="write to FILE instead of stdout"
           &comp=$edit:complete-filename~]
  &oflag= [&desc="write as per the comma separated symbol list"
           &comp={|arg| -comma-sep-list $-flags $arg }]
  &seek=  [&desc="skip N obs-sized blocks at start of output"]
  &skip=  [&desc="skip N ibs-sized blocks at start of input"]
  &status=[&desc="The LEVEL of information to print to stderr"
           &comp={|arg| all [none noxfer progress] }]
]

fn -completer {|@cmd|
  var last-arg = $cmd[-1]
  var op-length = (str:index $last-arg '=')

if (== -1 $op-length) {
  for op [(keys $-operands)] {
    edit:complex-candidate &display=$op'=  ('$-operands[$op][desc]')' &code-suffix='=' $op
  }

  edit:complex-candidate &display="--help  (display help and exit)" '--help'
  edit:complex-candidate &display="--version  (output version information and exit)" '--version'

} else {
  var op = $last-arg[..$op-length]
  var arg = $last-arg[(+ 1 $op-length)..]

  if (has-key $-operands[$op] comp) {
    $-operands[$op][comp] $arg | each {|candidate|

if (eq (kind-of $candidate) map) {
          put (edit:complex-candidate $op'='$candidate[stem] &display=$candidate[display])
        } else {
          put $op'='$candidate
        }
      }
    }
  }
}

set edit:completion:arg-completer[dd] = $-completer~
