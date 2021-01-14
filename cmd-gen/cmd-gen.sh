#!/bin/bash

#TODO: WRITE HELP, TEST

set -u

readonly G_SCRIPT_NAME="$0"
readonly G_SCRIPT_VERSION="0.9"

readonly G_OPT_FLD_NM_S="-n"
readonly G_OPT_FLD_NM_L="--fields"
readonly G_MATCH_FLD_NM="@($G_OPT_FLD_NM_S|$G_OPT_FLD_NM_L)"
G_FLD_NUM="0"

readonly G_POS_REGX_S="-r"
readonly G_POS_REGX_L="--pos-regex"
readonly G_MATCH_POS_REGX="@($G_POS_REGX_S|$G_POS_REGX_L)"
G_POS_REGX="0"

readonly G_OPT_SYNTX_STR_S="-s"
readonly G_OPT_SYNTX_STR_L="--syntax-str"
readonly G_MATCH_SYNTX_STR="@($G_OPT_SYNTX_STR_S|$G_OPT_SYNTX_STR_L)"
G_SYNTX_STR="0"

readonly G_OPT_CMD_S="-c"
readonly G_OPT_CMD_L="--command"
readonly G_MATCH_CMD="@($G_OPT_CMD_S|$G_OPT_CMD_L)"
G_CMD_LINE="0"

readonly G_OPT_SYNTX_CHECK_S="-S"
readonly G_OPT_SYNTX_CHECK_L="--syntax-check"
readonly G_MATCH_SYNTX_CHK="@($G_OPT_SYNTX_CHECK_S|$G_OPT_SYNTX_CHECK_L)"
G_SYNTX_CHK="0"

readonly G_OPT_DRY_RUN_S="-d"
readonly G_OPT_DRY_RUN_L="--dry-run"
readonly G_MATCH_DRY_RUN="@($G_OPT_DRY_RUN_S|$G_OPT_DRY_RUN_L)"
G_DRY_RUN=""

readonly G_OPT_HELP_S="-h"
readonly G_OPT_HELP_L="--help"
readonly G_MATCH_HELP="@($G_OPT_HELP_S|$G_OPT_HELP_L)"

readonly G_OPT_VER_S="-v"
readonly G_OPT_VER_L="--version"
readonly G_MATCH_VER="@($G_OPT_VER_L|$G_OPT_VER_S)"

G_FILES=""

function print_fd2    { echo "$@" >&2; }
function error_print  { print_fd2 "$0: error: $@"; }
function error_exit   { error_print "$@"; exit_failure; }
function exit_success { exit 0; }
function exit_failure { exit 1; } 

function print_use
{
	print_fd2 "Use: $G_SCRIPT_NAME <option> [args..]"
	print_fd2 "Try '$G_SCRIPT_NAME $G_OPT_HELP_L' for help"
	exit_failure
}
function assert_main_arg_num
{
	if [ "$#" -lt 1 ]; then
		print_use
	fi
}

function set_fld_num   { G_FLD_NUM="$2"; }
function set_pos_regx  { G_POS_REGX="$2"; }
function set_syntx_str { G_SYNTX_STR="$2"; }
function set_syntx_chk { G_SYNTX_CHK="$2"; }
function set_cmd       { G_CMD_LINE="$2"; }
function set_dry_run   { G_DRY_RUN="yes"; }

function print_help
{
	echo "help here"
	exit_success
}

function print_version
{
	echo "$G_SCRIPT_NAME $G_SCRIPT_VERSION"
	exit_success
}

function get_args
{
	shopt -s extglob
	
	local L_UNBOUND_ARG="-*"
	
	while [ "$#" -gt 0 ]; do
		local L_OPT_ARG=""
		local L_OPT_NO_ARG=""
		
		case "$1" in
		 $G_MATCH_FLD_NM)
			L_OPT_ARG="set_fld_num"
		 ;;
		 $G_MATCH_POS_REGX)
			L_OPT_ARG="set_pos_regx"
		 ;;
		 $G_MATCH_SYNTX_STR)
			L_OPT_ARG="set_syntx_str"
		 ;;
		 $G_MATCH_SYNTX_CHK)
			L_OPT_ARG="set_syntx_chk"
		 ;;
		 $G_MATCH_CMD)
			L_OPT_ARG="set_cmd"
		 ;;
		 $G_MATCH_DRY_RUN)
			L_OPT_NO_ARG="set_dry_run"
		 ;;
		 $G_MATCH_HELP)
			L_OPT_NO_ARG="print_help"
		 ;;
		 $G_MATCH_VER)
			L_OPT_NO_ARG="print_version"
		 ;;
		 $L_UNBOUND_ARG)
			error_exit "'$1' uknown option"
		 ;;
		 *)
			G_FILES="${G_FILES}'$1' "
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

function main
{
	assert_main_arg_num "$@"
	get_args "$@"
	call_awk
}

function call_awk
{
	if [ "$G_CMD_LINE" == "0" ]; then
		error_exit "'$G_OPT_CMD_L' not given"
	fi
	
	awk_it "$G_FLD_NUM"\
		"$G_POS_REGX"\
		"$G_SYNTX_STR"\
		"$G_SYNTX_CHK"\
		"$G_CMD_LINE"\
		"$G_FILES"
}

function awk_it
{
	local L_FLD_NUM="$1"
	local L_POS_REGX="$2"
	local L_SYNTAX_STR="$3"
	local L_SYNTAX_CHK="$4"
	local L_CMD_LINE="$5"
	local L_FILES="$6"

readonly local L_SRC='
function get_fld_syntax_err_str(fld_num,    err_str, res) {
	res = get_file_pos()
	res = sprintf("%s: %d fields expected, but fld_num %d fields instead",
		res, fld_num, get_fld_num())
	
	err_str = get_syntx_str()
	if (err_str)
		res = sprintf("%s; syntax should be \"%s\"", res, err_str)
		
	return res
}	

function get_rx_syntax_err_str(fld_num, fld_str, fld_rx,    res) {
	res = get_file_pos()
	res = sprintf("field %d \"%s\" should match \"%s\", but does not",
				fld_num, fld_str, fld_rx)
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
function set_pos_regx(pr)  {_B_pos_regx = pr}
function get_pos_regx()    {return _B_pos_regx}
function set_check_rx(crx) {_B_check_crx = crx}
function get_check_rx()    {return _B_check_crx}
function set_cmd_line(cl)  {_B_cmd_line = cl}
function get_cmd_line()    {return _B_cmd_line}

function init() {
	set_prog_name(ProgName ? ProgName : ARGV[0])
	set_fld_num(FldNum ? FldNum : 2)
	set_pos_regx(PosRegx ? PosRegx : "#%d")
	set_syntx_str(SyntaxStr ? SyntaxStr : "")
	set_check_rx(SyntaxChk ? SyntaxChk : "")
	
	if (CmdLine)
		set_cmd_line(CmdLine)
	else
		err_quit("-vCmdLine not given")
}

function check_field(field, fnum,    chk_rx, arr1, len1, arr2, len2, i, j, rx) {
	chk_rx = get_check_rx()
	
	if (!chk_rx)
		return
	
	len1 = split(chk_rx, arr1, ";")
	for (i = 1; i <= len1; ++i) {
		
		len2 = split(arr1[i], arr2, "~")
		rx = arr2[2]
		if ((fnum == arr2[1]) && !match(field, rx))
			err_quit(get_rx_syntax_err_str(fnum, field, rx))
	}
}

function gen_cmd(arr, len,    i, cmd, regx, fld) {
	cmd = get_cmd_line()
	for (i = 1; i <= len; ++i) {
		fld = arr[i]
		
		check_field(fld, i)
		regx = sprintf(get_pos_regx(), i)
		gsub(regx, fld, cmd)
	}
	return cmd
}

function process_line(fname, linenum, str,    arr, len) {
	len = split(str, arr)
	if (len != get_fld_num())
		err_quit(get_fld_syntax_err_str(len))
	return gen_cmd(arr, len)
}

BEGIN {init()}
$0 ~ /^[[:space:]]*$/ {next}
$0 ~ /^[[:space:]]*#/ {next}
{print process_line(FILENAME, FNR, $0)}
'	
	echo_eval "awk -vProgName='$0' "\
		"-vFldNum='$L_FLD_NUM' "\
		"-vPosRegx='$L_POS_REGX' "\
		"-vSyntaxStr='$L_SYNTAX_STR' "\
		"-vSyntaxChk='$L_SYNTAX_CHK' "\
		"-vCmdLine='$L_CMD_LINE' "\
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
