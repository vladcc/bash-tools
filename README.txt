# bash-tools
bashtest/ - bash testing library; assert, diff, stack trace, etc

genbash/  - generate bash boilerplate with argument parsing and error reporting
code in place

prep/     - generate strings with positional arguments from the command line,
e.g. 
$ echo host port | bash prep.sh -s 'nc -vz #1 #2'
nc -vz host port
