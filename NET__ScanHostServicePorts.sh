#!/bin/sh

############################################################################################################
############################################################################################################
###
###	$Id: NET__ScanHostServicePorts.sh,v 1.1 2020/09/07 23:34:06 root Exp $
###
###	Scan service ports on current host.
###
############################################################################################################
############################################################################################################

###	FUTURES:  Review output of other 'scripts' for possible benefits


#nmap -vv -T5 -p1-65535 `hostname -I`
#nmap -vv -T5 `hostname -I`/24

tester=`which nmap `
if [ -z "${tester}" ]
then
	echo "\n\t Utility 'nmap' is not installed.  Unable to perform requested action.  Bye!\n" ; exit 1
fi

nmap -vv T5 -p1-65535 --script "default and safe" `hostname -I`
