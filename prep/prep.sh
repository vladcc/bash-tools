#!/bin/bash

# Author: Vladimir Dinev
# vld.dinev@gmail.com
# 2021-01-20

set -u

readonly G_SCRIPT_NAME="$(basename $0)"
readonly G_SCRPIT_DIR="$(dirname $(realpath $0))"
readonly G_SCRIPT_VER="1.0"
function print_version { echo "$G_SCRIPT_NAME $G_SCRIPT_VER"; }

function print_fd2    { echo "$@" >&2; }
function error_print  { print_fd2 "$0: error: $@"; }
function error_exit   { error_print "$@"; exit_failure; }
function exit_success { exit 0; }
function exit_failure { exit 1; }

readonly G_OPT_NUM_FIELDS_S="-f"
readonly G_OPT_NUM_FIELDS_L="--fields"
readonly G_MATCH_NUM_FIELDS="@($G_OPT_NUM_FIELDS_S|$G_OPT_NUM_FIELDS_L)"
G_NUM_FIELDS=""

readonly G_OPT_FIELD_SEP_S="-F"
readonly G_OPT_FIELD_SEP_L="--field-sep"
readonly G_MATCH_FIELD_SEP="@($G_OPT_FIELD_SEP_S|$G_OPT_FIELD_SEP_L)"
G_FIELD_SEP=""

readonly G_OPT_POS_SPEC_S="-p"
readonly G_OPT_POS_SPEC_L="--pos-spec"
readonly G_MATCH_POS_SPEC="@($G_OPT_POS_SPEC_S|$G_OPT_POS_SPEC_L)"
G_POS_SPEC=""

readonly G_OPT_SYNTAX_STR_S="-t"
readonly G_OPT_SYNTAX_STR_L="--syntax-str"
readonly G_MATCH_SYNTAX_STR="@($G_OPT_SYNTAX_STR_S|$G_OPT_SYNTAX_STR_L)"
G_SYNTAX_STR=""

readonly G_OPT_STRING_S="-s"
readonly G_OPT_STRING_L="--string"
readonly G_MATCH_STRING="@($G_OPT_STRING_S|$G_OPT_STRING_L)"
G_STRING=""

readonly G_OPT_SYNTAX_CHECK_S="-c"
readonly G_OPT_SYNTAX_CHECK_L="--syntax-check"
readonly G_MATCH_SYNTAX_CHECK="@($G_OPT_SYNTAX_CHECK_S|$G_OPT_SYNTAX_CHECK_L)"
G_SYNTAX_CHECK=""

readonly G_OPT_DRY_RUN_S="-d"
readonly G_OPT_DRY_RUN_L="--dry-run"
readonly G_MATCH_DRY_RUN="@($G_OPT_DRY_RUN_S|$G_OPT_DRY_RUN_L)"
G_DRY_RUN=""

readonly G_OPT_HELP_S="-h"
readonly G_OPT_HELP_L="--help"
readonly G_MATCH_HELP="@($G_OPT_HELP_S|$G_OPT_HELP_L)"
G_HELP=""

readonly G_OPT_VERSION_S="-v"
readonly G_OPT_VERSION_L="--version"
readonly G_MATCH_VERSION="@($G_OPT_VERSION_S|$G_OPT_VERSION_L)"
G_VERSION=""

G_CMD_LINE_OTHER=""

function set_num_fields { G_NUM_FIELDS="$2"; }
function set_field_sep { G_FIELD_SEP="-F'$2'"; }
function set_pos_spec { G_POS_SPEC="$2"; }
function set_syntax_str { G_SYNTAX_STR="$2"; }
function set_string { G_STRING="$2"; }
function set_syntax_check { G_SYNTAX_CHECK="$2"; }
function set_dry_run { G_DRY_RUN="yes"; }
function set_help { G_HELP="yes"; print_help; }
function set_version { G_VERSION="yes"; print_version; }

function get_args
{
	shopt -s extglob
	local L_UNBOUND_ARG="-*"

	while [ "$#" -gt 0 ]; do
		local L_OPT_ARG=""
		local L_OPT_NO_ARG=""

		case "$1" in
			$G_MATCH_NUM_FIELDS)
				L_OPT_ARG="set_num_fields"
			;;
			$G_MATCH_FIELD_SEP)
				L_OPT_ARG="set_field_sep"
			;;
			$G_MATCH_POS_SPEC)
				L_OPT_ARG="set_pos_spec"
			;;
			$G_MATCH_SYNTAX_STR)
				L_OPT_ARG="set_syntax_str"
			;;
			$G_MATCH_STRING)
				L_OPT_ARG="set_string"
			;;
			$G_MATCH_SYNTAX_CHECK)
				L_OPT_ARG="set_syntax_check"
			;;
			$G_MATCH_DRY_RUN)
				L_OPT_NO_ARG="set_dry_run"
			;;
			$G_MATCH_HELP)
				L_OPT_NO_ARG="set_help"
			;;
			$G_MATCH_VERSION)
				L_OPT_NO_ARG="set_version"
			;;
			$L_UNBOUND_ARG)
				error_exit "'$1' unknown option"
			;;
			*)
				G_CMD_LINE_OTHER="${G_CMD_LINE_OTHER}'$1' "
			;;
		esac

		if [ ! -z "$L_OPT_ARG" ]; then
			if [ "$#" -lt 2 ] || [ "${2:0:1}" == "-" ]; then
				error_exit "'$1' missing argument"
			fi
			eval "$L_OPT_ARG '$1' '$2'"
			shift 2
		elif [ ! -z "$L_OPT_NO_ARG" ]; then
			eval "$L_OPT_NO_ARG '$1'"
			shift
		else
			shift
		fi
	done
}

function print_version
{
	echo "$G_VER_STR"
	exit_success
}

readonly G_VER_STR="$G_SCRIPT_NAME $G_SCRIPT_VER"
readonly G_USE_STR="Use: $G_SCRIPT_NAME <option> [args..] [files]"
function print_use
{
	print_fd2 "$G_USE_STR"
	print_fd2 "Try '$G_SCRIPT_NAME $G_OPT_HELP_L' for help"
	exit_failure
}

function print_help
{
echo "$G_USE_STR"
echo "Generates strings using positional arguments from the command line. Input"
echo "is stdin if no files are given. Empty lines and lines beginning with a"
echo "'#' are ignored."
echo ""
echo "$G_OPT_NUM_FIELDS_S, $G_OPT_NUM_FIELDS_L <num>"
echo "Expect input to have <num> number of fields per line or quit with an"
echo "error. Default is 2."
echo ""
echo "$G_OPT_FIELD_SEP_S, $G_OPT_FIELD_SEP_L <field-sep>"
echo "Passes <field-sep> to awk. E.g."
echo "$ echo 'a;b' | $G_SCRIPT_NAME $G_OPT_FIELD_SEP_S ';' -s 'ls #0 #1 #2'"
echo "ls a;b a b"
echo ""
echo "$G_OPT_POS_SPEC_S, $G_OPT_POS_SPEC_L <fmt-str>"
echo "Change the positional argument string. Default is '#%d', i.e. a '#'"
echo "followed by a number. Note that this limits the number of positional"
echo "arguments to 9, since only the '#1' in '#10' will be matched and"
echo "replaced. E.g."
echo "$ echo a b c d e f g h i j | $G_SCRIPT_NAME $G_OPT_NUM_FIELDS_S 10 $G_OPT_STRING_S 'ls #1 #10'"
echo "ls a a0"
echo "If more than 9 positional arguments are needed, <fmt-str> should include"
echo "an end delimiter, e.g. '#%d#'"
echo "$ echo a b c d e f g h i j | $G_SCRIPT_NAME $G_OPT_NUM_FIELDS_S 10 $G_OPT_POS_SPEC_S '#%d#'  $G_OPT_STRING_S 'ls #1# #10#'"
echo "ls a j"
echo ""
echo "$G_OPT_SYNTAX_STR_S, $G_OPT_SYNTAX_STR_L <expected-syntax>"
echo "Syntax clarification string. E.g."
echo "$ echo a b c | $G_SCRIPT_NAME $G_OPT_STRING_S 'nc #1 #2'"
echo "prep.sh: error: file "-", line 1: \"a b c\": 2 fields expected, but got 3 instead"
echo "vs."
echo "$ echo a b c | $G_SCRIPT_NAME $G_OPT_STRING_S 'nc #1 #2' $G_OPT_SYNTAX_STR_S '<host> <port>'"
echo "prep.sh: error: file "-", line 1: \"a b c\": 2 fields expected, but got 3 instead; syntax should be \"<host> <port>\""
echo ""
echo "$G_OPT_STRING_S, $G_OPT_STRING_L <string-with-pos-args>"
echo "The string to operate on."
echo ""
echo "$G_OPT_SYNTAX_CHECK_S, $G_OPT_SYNTAX_CHECK_L <<fnum>~<regex>;<fnum>~<regex>...>"
echo "Matches the field with number <fnum> to its respective <regex>. If the"
echo "match fails, quit with an error. Effectively, this allows for regex"
echo "syntax checks. E.g."
echo "$ echo a b | $G_SCRIPT_NAME $G_OPT_STRING_S 'nc #1 #2' $G_OPT_SYNTAX_CHECK_S '1~^localhost$'"
echo "prep.sh: error: file \"-\", line 1: \"a b\": field 1 \"a\" should match \"^localhost$\", but does not"
echo "$ echo localhost b | $G_SCRIPT_NAME $G_OPT_STRING_S 'nc #1 #2' $G_OPT_SYNTAX_CHECK_S '1~^localhost$'"
echo "nc localhost b"
echo "$ echo localhost b | $G_SCRIPT_NAME $G_OPT_STRING_S 'nc #1 #2' $G_OPT_SYNTAX_CHECK_S '1~^localhost$;2~^[0-9]+$'"
echo "prep.sh: error: file \"-\", line 1: \"localhost b\": field 2 \"b\" should match \"^[0-9]+$\", but does not"
echo "$ echo localhost 8000 | $G_SCRIPT_NAME $G_OPT_STRING_S 'nc #1 #2' $G_OPT_SYNTAX_CHECK_S '1~^localhost$;2~^[0-9]+$'"
echo "nc localhost 8000"
echo ""
echo "$G_OPT_DRY_RUN_S, $G_OPT_DRY_RUN_L"
echo "Print the commands which constitute this script, but do not execute them."
echo ""
echo "$G_OPT_HELP_S, $G_OPT_HELP_L"
echo "Print this screen."
echo ""
echo "$G_OPT_VERSION_S, $G_OPT_VERSION_L"
echo "Print version information."
	exit_success
}

function main
{
	assert_main_arg_num "$@"
	get_args "$@"
	call_awk
}

function assert_main_arg_num
{
	if [ "$#" -lt 1 ]; then
		print_use
	fi
}

function call_awk
{
	if [ -z "$G_STRING" ]; then
		error_exit "'$G_OPT_STRING_L' not given"
	fi
	
	awk_it "$G_FIELD_SEP"\
		"$G_NUM_FIELDS"\
		"$G_POS_SPEC"\
		"$G_SYNTAX_STR"\
		"$G_SYNTAX_CHECK"\
		"$G_STRING"\
		"$G_CMD_LINE_OTHER"
}

function awk_it
{
	local L_FLD_SEP="$1"
	local L_FLD_NUM="$2"
	local L_POS_SPEC="$3"
	local L_SYNTAX_STR="$4"
	local L_SYNTAX_CHK="$5"
	local L_STRING_LINE="$6"
	local L_FILES="$7"

readonly local L_SRC='
function get_fld_syntax_err_str(fld_num,    err_str, res) {
	res = get_file_pos()
	res = sprintf("%s: %d fields expected, but got %d instead",
		res, get_fld_num(), fld_num)
	
	err_str = get_syntx_str()
	if (err_str)
		res = sprintf("%s; syntax should be \"%s\"", res, err_str)
		
	return res
}	

function get_rx_syntax_err_str(fld_num, fld_str, fld_rx,    res) {
	res = get_file_pos()
	res = sprintf("%s: field %d \"%s\" should match \"%s\", but does not",
				res, fld_num, fld_str, fld_rx)
	return res
}

function get_file_pos() {
	return sprintf("file \"%s\", line %d: \"%s\"",
		FILENAME, FNR, $0)
}

function err_quit(msg,    err_msg) {
	err_msg = sprintf("%s: error: %s", get_prog_name(), msg)
	print err_msg > "/dev/stderr"
	exit(1)
}

function set_prog_name(pn) {_B_prog_name = pn}
function get_prog_name()   {return _B_prog_name}
function set_fld_num(fn)   {_B_fld_num = fn}
function get_fld_num()     {return _B_fld_num}
function set_syntx_str(sx) {_B_err_str = sx}
function get_syntx_str()   {return _B_err_str}
function set_pos_spec(pr)  {_B_pos_spec = pr}
function get_pos_spec()    {return _B_pos_spec}
function set_check_rx(fnum, crx) {_B_check_crx[fnum] = crx}
function get_check_rx(fnum)      {return _B_check_crx[fnum]}
function set_string_line(cl) {_B_string_line = cl}
function get_string_line()   {return _B_string_line}


function init() {
	set_prog_name(ProgName ? ProgName : ARGV[0])
	set_fld_num(FldNum ? FldNum : 2)
	set_pos_spec(PosRegx ? PosRegx : "#%d")
	set_syntx_str(SyntaxStr ? SyntaxStr : "")
	
	if (SyntaxChk)
		process_check_rx(SyntaxChk)
	
	if (TheString)
		set_string_line(TheString)
	else
		err_quit("-vTheString not given")
}

function CHK_RX_RS() {return ";"}
function CHK_RX_FS() {return "~"}
function CHK_RX() {return "^[0-9]+~.+$"}
function process_check_rx(chk_rx,    chk1, i, arr1, len1, arr2) {
	
	len1 = split(chk_rx, arr1, CHK_RX_RS())
	for (i = 1; i <= len1; ++i) {
		chk1 = arr1[i]
		
		if (!match(chk1, CHK_RX()))
			err_quit(sprintf("\"%s\" should match %s, but does not",
				chk1, CHK_RX()))
		
		split(chk1, arr2, CHK_RX_FS())
		set_check_rx(arr2[1], arr2[2])
	}
}

function check_field(field, fnum,    chk_rx) {
		chk_rx = get_check_rx(fnum)
		if (chk_rx && !match(field, chk_rx))
			err_quit(get_rx_syntax_err_str(fnum, field, chk_rx))
}

function gen_str(arr, len,    i, str, regx, fld) {
	str = get_string_line()
	for (i = 0; i <= len; ++i) {
		fld = arr[i]
		
		check_field(fld, i)
		regx = sprintf(get_pos_spec(), i)
		gsub(regx, fld, str)
	}
	return str
}

function process_line(fname, linenum, str,    arr, len) {
	len = split(str, arr)
	arr[0] = str
	if (len != get_fld_num())
		err_quit(get_fld_syntax_err_str(len))
	return gen_str(arr, len)
}

BEGIN {init()}
$0 ~ /^[[:space:]]*$/ {next}
$0 ~ /^[[:space:]]*#/ {next}
{print process_line(FILENAME, FNR, $0)}
'	
	echo_eval "awk $L_FLD_SEP "\
		"-vProgName='$0' "\
		"-vFldNum='$L_FLD_NUM' "\
		"-vPosRegx='$L_POS_SPEC' "\
		"-vSyntaxStr='$L_SYNTAX_STR' "\
		"-vSyntaxChk='$L_SYNTAX_CHK' "\
		"-vTheString='$L_STRING_LINE' "\
		"'$L_SRC' "\
		"$L_FILES"
}

function echo_eval
{
	if [ ! -z "$G_DRY_RUN" ]; then
		echo "$@"
	else
		eval "$@"
	fi
}

main "$@"
