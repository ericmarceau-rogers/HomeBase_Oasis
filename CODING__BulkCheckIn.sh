#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: CODING__BulkCheckIn.sh,v 1.3 2024/09/07 16:47:04 root Exp root $
###
###	Scipt to simplify mass check-in of coding files which were checked-out with lock.
###
####################################################################################################

doitBulk()
{
	if [ -s RCS/${file},v ]
	then
		./RCS__LastDiff_FW_DROP.sh --script ${file}
		echo "\n"
		ci -u ${file}
	fi
}

if [ "$1" = "--all" ]
then
	for file in *.sh
	do
		doitBulk
	done
else
	for file in `CODING__CheckRCSnames.sh --names `
	do
		doitBulk
	done
fi

exit 0
exit 0
exit 0
