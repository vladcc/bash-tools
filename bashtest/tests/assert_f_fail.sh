#!/bin/bash

function main
{
	pushd "$(dirname $(realpath $0))" > /dev/null
	source "../bashtest.sh"
	popd > /dev/null
	 
	bt_enter
	test_assert
	bt_exit_success
}

function test_assert
{
	bt_eval true
	bt_assert_failure
}

main "$@"
