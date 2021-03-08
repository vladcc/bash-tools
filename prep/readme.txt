Use: prep.sh <option> [args..] [files]
Generates strings using positional arguments from the command line. Input
is stdin if no files are given. Empty lines and lines beginning with a
'#' are ignored.

-f, --fields <num>
Expect input to have <num> number of fields per line or quit with an
error. Default is 2.

-F, --field-sep <field-sep>
Passes <field-sep> to awk. E.g.
$ echo 'a;b' | prep.sh -F ';' -s 'ls #0 #1 #2'
ls a;b a b

-p, --pos-spec <fmt-str>
Change the positional argument string. Default is '#%d', i.e. a '#'
followed by a number.

-t, --syntax-str <expected-syntax>
Syntax clarification string. E.g.
$ echo a b c | prep.sh -s 'nc #1 #2'
prep.sh: error: file -, line 1: "a b c": 2 fields expected, but got 3 instead
vs.
$ echo a b c | prep.sh -s 'nc #1 #2' -t '<host> <port>'
prep.sh: error: file -, line 1: "a b c": 2 fields expected, but got 3 instead; syntax should be "<host> <port>"

-s, --string <string-with-pos-args>
The string to operate on.

-c, --syntax-check <<fnum>~<regex>;<fnum>~<regex>...>
Matches the field with number <fnum> to its respective <regex>. If the
match fails, quit with an error. Effectively, this allows for regex
syntax checks. E.g.
$ echo a b | prep.sh -s 'nc #1 #2' -c '1~^localhost$'
prep.sh: error: file "-", line 1: "a b": field 1 "a" should match "^localhost$"
$ echo localhost b | prep.sh -s 'nc #1 #2' -c '1~^localhost$'
nc localhost b
$ echo localhost b | prep.sh -s 'nc #1 #2' -c '1~^localhost$;2~^[0-9]+$'
prep.sh: error: file "-", line 1: "localhost b": field 2 "b" should match "^[0-9]+$"
$ echo localhost 8000 | prep.sh -s 'nc #1 #2' -c '1~^localhost$;2~^[0-9]+$'
nc localhost 8000

-d, --dry-run
Print the commands which constitute this script, but do not execute them.

-h, --help
Print this screen.

-v, --version
Print version information.
