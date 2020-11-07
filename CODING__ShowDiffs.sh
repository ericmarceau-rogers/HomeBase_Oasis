#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: CODING__ShowDiffs.sh,v 1.1 2020/09/14 21:06:41 root Exp $
###
###	Script to report specifics for all files where differences exist from an existing RCS version.
###
####################################################################################################

TMP=/tmp/`basename "$0" ".sh" `.tmp
rm -f ${TMP}

CODING__CheckRCSnames.sh --names >${TMP}

if [ ! -s ${TMP} ]
then
	echo "\n\t No code discrepancies identified between versions of scripts in PATH vs versions in RCS.\n Bye!\n" ; exit 0
fi

for file in `cat ${TMP} `
do
	RCS__LastDiff_FW_DROP.sh --script ${file}
	echo "\n\t Hit return to continue => \c" ; read k
done
