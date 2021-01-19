#!/bin/bash

G_BASE_DIR="$(dirname $(realpath $0))"

function run_prep
{
	bash ../prep.sh $@
}

function main
{
	source "$G_BASE_DIR/bashtest.sh"
	
	if [ "$#" -gt 0 ]; then
		bt_set_verbose
	fi
	
	bt_enter
	
	test_err
	#run_prep
	#bt_assert_failure
	
	bt_exit_success
	
}

function test_err
{

local L_GOT=""
L_GOT="$(run_prep 2>&1 || \
run_prep '-f' 2>&1 || run_prep '-F' 2>&1 || run_prep '-p' 2>&1 || run_prep '-t' 2>&1 || \
run_prep '-s' 2>&1 || run_prep '-c' 2>&1 || run_prep '-d' 2>&1 || \
run_prep '--fields' 2>&1 || run_prep '--field_sep' 2>&1 || run_prep '--pos-spec' 2>&1 || \
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
../prep.sh: error: '--field_sep' missing argument
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
L_EXP='../prep.sh: error: "foo" should match ^[0-9]+~.+$, but does not'
	bt_diff "<(echo \"$L_GOT\")" "<(echo \"$L_EXP\")"
	bt_assert_success
}

function test_ok
{
	:
}

main "$@"
