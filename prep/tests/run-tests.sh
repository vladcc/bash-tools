#!/bin/bash

G_BASE_DIR="$(dirname $(realpath $0))"

function run_prep
{
	bash ../prep.sh "$@"
}

function main
{
	source "$G_BASE_DIR/bashtest.sh"
	
	if [ "$#" -gt 0 ]; then
		bt_set_verbose
	fi
	
	bt_enter
	test_err
	test_ok
	bt_exit_success
	
}

function test_err
{

local L_GOT=""
L_GOT="$(run_prep 2>&1 || \
run_prep '-f' 2>&1 || run_prep '-F' 2>&1 || run_prep '-p' 2>&1 || run_prep '-t' 2>&1 || \
run_prep '-s' 2>&1 || run_prep '-c' 2>&1 || run_prep '-d' 2>&1 || \
run_prep '--fields' 2>&1 || run_prep '--field-sep' 2>&1 || run_prep '--pos-spec' 2>&1 || \
run_prep '--syntax-str' 2>&1 || run_prep '--string' 2>&1 || run_prep '--syntax-check' 2>&1 || \
run_prep '--dry-run' 2>&1 || run_prep -u 2>&1 || run_prep --unknown 2>&1)"
	bt_assert_failure
	
local L_EXP="Use: prep.sh <option> [args..] [files]
Try 'prep.sh --help' for help
../prep.sh: error: '-f' missing argument
../prep.sh: error: '-F' missing argument
../prep.sh: error: '-p' missing argument
../prep.sh: error: '-t' missing argument
../prep.sh: error: '-s' missing argument
../prep.sh: error: '-c' missing argument
../prep.sh: error: '--string' not given
../prep.sh: error: '--fields' missing argument
../prep.sh: error: '--field-sep' missing argument
../prep.sh: error: '--pos-spec' missing argument
../prep.sh: error: '--syntax-str' missing argument
../prep.sh: error: '--string' missing argument
../prep.sh: error: '--syntax-check' missing argument
../prep.sh: error: '--string' not given
../prep.sh: error: '-u' unknown option
../prep.sh: error: '--unknown' unknown option"
	bt_diff "<(echo \"$L_GOT\")" "<(echo \"$L_EXP\")"
	bt_assert_success
	
L_GOT="$(run_prep -s str -c 'foo' 2>&1)"
	bt_assert_failure
L_EXP='../prep.sh: error: "foo" should match "^[0-9]+~.+$"'
	bt_diff "<(echo \"$L_GOT\")" "<(echo \"$L_EXP\")"
	bt_assert_success
}

function test_ok
{
	local L_GOT=""
	L_GOT="$(echo host port | run_prep -s 'nc -vz #1 #2')"
	bt_assert_success
	
	# trivial
	local L_EXP="nc -vz host port"
	bt_diff "<(echo \"$L_GOT\")" "<(echo \"$L_EXP\")"
	bt_assert_success

	# field sep + multiple lines
	local L_MLN=\
"$(echo 'foo;bar;baz'; echo '#'; echo 'zig;zag;zog'; echo ""; echo '1;2;3'; echo "")"
	L_GOT="$(echo "$L_MLN" | run_prep -f 3 -F ';' -s 'ls #1 #2 #3 #0 #3 #2 #1')"
	bt_assert_success
	
	L_EXP="ls foo bar baz foo;bar;baz baz bar foo
ls zig zag zog zig;zag;zog zog zag zig
ls 1 2 3 1;2;3 3 2 1"
	bt_diff "<(echo \"$L_GOT\")" "<(echo \"$L_EXP\")"
	bt_assert_success
	
	# as a file
	L_GOT="$(run_prep -f 3 -F ';' -s 'ls #1 #2 #3 #0 #3 #2 #1' <(echo "$L_MLN"))"
	bt_assert_success
	bt_diff "<(echo \"$L_GOT\")" "<(echo \"$L_EXP\")"
	bt_assert_success
	
	# multiple files
	L_GOT="$(run_prep <(echo foo bar) -s 'ls #1 #2' <(echo baz zig))"
	bt_assert_success
	L_EXP="ls foo bar
ls baz zig"
	bt_diff "<(echo \"$L_GOT\")" "<(echo \"$L_EXP\")"
	bt_assert_success
	
	# help examples short
	L_GOT="$(echo 'a;b' | run_prep -F ';' -s 'ls #0 #1 #2')"
	bt_assert_success
	bt_diff "<(echo \"$L_GOT\")" "<(echo 'ls a;b a b')"
	bt_assert_success
	
	L_GOT="$(echo a b c d e f g h i j | run_prep -f 10 -s 'ls #1 #10')"
	bt_assert_success
	bt_diff "<(echo \"$L_GOT\")" "<(echo 'ls a j')"
	bt_assert_success
	
	L_GOT="$(echo a b c d e f g h i j | run_prep -f 10 -p '#%d#' -s 'ls #1# #10#')"
	bt_assert_success
	bt_diff "<(echo \"$L_GOT\")" "<(echo 'ls a j')"
	bt_assert_success
	
	L_GOT="$(echo a b c | run_prep -s 'nc #1 #2' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b c": 2 fields expected, but got 3 instead'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo a b c | run_prep -s 'nc #1 #2' -t '<host> <port>' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b c": 2 fields expected, but got 3 instead; syntax should be "<host> <port>"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo a b | run_prep -s 'nc #1 #2' -c '1~^localhost$' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b": field 1 "a" should match "^localhost$"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo localhost b | run_prep -s 'nc #1 #2' -c '1~^localhost$' 2>&1)"
	bt_assert_success
	bt_diff "<(echo '$L_GOT')" "<(echo 'nc localhost b')"
	bt_assert_success
	
	L_GOT="$(echo localhost b | run_prep -s 'nc #1 #2' -c '1~^localhost$;2~^[0-9]+$' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "localhost b": field 2 "b" should match "^[0-9]+$"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo localhost 8000 | run_prep -s 'nc #1 #2' -c '1~^localhost$;2~^[0-9]+$' 2>&1)"
	bt_assert_success
	bt_diff "<(echo '$L_GOT')" "<(echo 'nc localhost 8000')"
	bt_assert_success
	
	# help examples long
	L_GOT="$(echo 'a;b' | run_prep --field-sep ';' --string 'ls #0 #1 #2')"
	bt_assert_success
	bt_diff "<(echo \"$L_GOT\")" "<(echo 'ls a;b a b')"
	bt_assert_success
	
	L_GOT="$(echo a b c d e f g h i j | run_prep --fields 10 --pos-spec '#%d#' --string 'ls #1# #10#')"
	bt_assert_success
	bt_diff "<(echo \"$L_GOT\")" "<(echo 'ls a j')"
	bt_assert_success
	
	L_GOT="$(echo a b c | run_prep --string 'nc #1 #2' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b c": 2 fields expected, but got 3 instead'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo a b c | run_prep --string 'nc #1 #2' --syntax-str '<host> <port>' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b c": 2 fields expected, but got 3 instead; syntax should be "<host> <port>"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo a b | run_prep --string 'nc #1 #2' --syntax-check '1~^localhost$' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b": field 1 "a" should match "^localhost$"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo localhost b | run_prep --string 'nc #1 #2' --syntax-check '1~^localhost$' 2>&1)"
	bt_assert_success
	bt_diff "<(echo '$L_GOT')" "<(echo 'nc localhost b')"
	bt_assert_success
	
	L_GOT="$(echo localhost b | run_prep --string 'nc #1 #2' --syntax-check '1~^localhost$;2~^[0-9]+$' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "localhost b": field 2 "b" should match "^[0-9]+$"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo localhost 8000 | run_prep --string 'nc #1 #2' --syntax-check '1~^localhost$;2~^[0-9]+$' 2>&1)"
	bt_assert_success
	bt_diff "<(echo '$L_GOT')" "<(echo 'nc localhost 8000')"
	bt_assert_success
	
	# misc
	bt_diff "<(run_prep -v)" "<(echo 'prep.sh 1.1')"
	bt_assert_success
	bt_diff "<(run_prep --version)" "<(echo 'prep.sh 1.1')"
	bt_assert_success
	bt_diff "<(run_prep -s foo -d | wc -l)" "<(echo 109)"
	bt_assert_success
	bt_diff "<(run_prep -s foo --dry-run | wc -l)" "<(echo 109)"
	bt_assert_success
	bt_diff "<(run_prep -h | wc -l)" "<(echo 50)"
	bt_assert_success
	bt_diff "<(run_prep --help | wc -l)" "<(echo 50)"
	bt_assert_success
	
	# non-default field num
	L_GOT="$(echo a b | run_prep -f 3 -s 'nc #1 #2' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b": 3 fields expected, but got 2 instead'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo a b | run_prep --fields 3 -s 'nc #1 #2' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b": 3 fields expected, but got 2 instead'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo a b | run_prep --fields 3 -t '<a> <b> <c>' -s 'nc #1 #2' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b": 3 fields expected, but got 2 instead; syntax should be "<a> <b> <c>"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
	
	L_GOT="$(echo a b | run_prep --fields 3 --syntax-str '<a> <b> <c>' -s 'nc #1 #2' 2>&1)"
	bt_assert_failure
	L_EXP='../prep.sh: error: file "-", line 1: "a b": 3 fields expected, but got 2 instead; syntax should be "<a> <b> <c>"'
	bt_diff "<(echo '$L_GOT')" "<(echo '$L_EXP')"
	bt_assert_success
}

main "$@"
