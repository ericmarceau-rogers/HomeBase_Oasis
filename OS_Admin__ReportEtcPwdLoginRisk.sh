#!/bin/sh

####################################################################################################
###
###	$Id: OS_Admin__ReportEtcPwdLoginRisk.sh,v 1.2 2020/08/19 21:04:51 root Exp $
###
###	This script will report all entries in the /etc/passwd file where login is not blocked.
###
####################################################################################################

##FIRSTBOOT##

echo "\n Below is list of entries in '/etc/passwd' where the specified shell\n is not one of  a) /usr/sbin/nologin   OR   b) /bin/false :\n"
grep -v '/usr/sbin/nologin' /etc/passwd | grep -v '/bin/false' | awk '{ printf("\t %s\n", $0 ) ; }'
echo ""
