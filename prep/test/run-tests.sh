#!/bin/bash

G_BASE_DIR="$(dirname $(realpath $0))"

function run_prep
{
	bt_eval "bash ../prep.sh $@"
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

run_prep
run_prep "-f"
run_prep "-F"
run_prep "-p"
run_prep "-t"
run_prep "-s"
run_prep "-c"
run_prep "-d"

}

main "$@"
