#!/bin/sh

###
###	Script to report the fragmentation status of all partitions on the drive
###

base=`basename "$0" ".sh" `
tmp="/tmp/${base}.$$.df"


df -h | grep '/dev/sd' | awk '{ print $1, $6 }' | sort -r --key=2.1,3.0 >"${tmp}"

dolist=""

while read dev label
do
	echo "\n Perform assessment on '${label}' ? [y|N] => \c" ; read ans <&2

	if [ -z "${ans}" ]
	then
		ans="N"
	fi

	case "${ans}" in
		y* | Y* ) dolist="${dolist} ${label}" ;;
		* ) ;;
	esac
done <"${tmp}"

#echo " dolist = ${dolist}"

for label in `echo ${dolist} `
do
	dev=`awk -v todo="${label}" '{ if( $2 == todo ){ print $1 ; } ; }' "${tmp}" `

	case "${label}" in
		"/" ) label="/DB001_F1" ;;
		* ) ;;
	esac
	
	descr=`echo "${label}" | cut -f2 -d/ `
	log="$Oasis/bin/${base}__${descr}.txt"

	echo "\n Evaluating fragmentation of partition '${label}' ..."
	echo "\t DEV = ${dev}"
	#echo "\t log = ${log}"

	# With '-c' option, will NEVER defrag
	rm -f "${log}"
	start=`date +%T.%N `
	e4defrag -c "${dev}" 2>&1 | tee "${log}" | awk '{ printf("\t %s\n", $0 ) ; }'
	finis=`date +%T.%N `
	echo "\nSTART = ${start}\n  END = ${finis}" | tee --append "${log}" | awk '{ printf("\t %s\n", $0 ) ; }'
done

exit
