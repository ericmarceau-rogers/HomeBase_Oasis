#!/bin/sh

###	$Id: $
###	Script to report fragmentation status of partitions.

FSCK="e2fsck"

SWAPS="0"
REPAIR="0"
VERB="0"
dACTION="Scan Report"

while [ $# -gt 0 ]
do
	case $1 in
		--swaps )
			SWAPS="1" ; shift
			;;
		--repair )
			REPAIR="1" ; shift
			dACTION="Filesystem REPAIR"
			;;
		--verbose )
			VERB="1" ; shift
			;;
		* )
			echo "\n\t ERROR:  Invalid option used.  Please try again.\n\n Bye! \n" ; exit 1
			;;
	esac
done

thisProg=`basename $0 ".sh" `

TMP=/tmp/tmp.${thisProg}.$$
rm -f ${TMP}.1

if [ ${REPAIR} = 1 ]
then
	Devices__ReportDiskParts.sh 2>>/dev/null | grep -v swap  | grep -v 'Not_Mounted' | sort >${TMP}.1
	echo "\n\t Skipping the following Mounted partitions:"
	cat ${TMP}.1 | awk '{ printf("\t %s\n", $0 ) }END{ print "" }'
	rm -f ${TMP}.1
	
	#df -h | grep '^/dev' | awk '{ printf("%s|%s\n", $6, $1) }' | sort -n >${TMP}.1
	Devices__ReportDiskParts.sh 2>>/dev/null | grep -v swap  | grep 'Not_Mounted' | awk '{ printf("%s|%s|%s\n", $6, $1, $2) }' | sort -r >${TMP}.1
else
	#df -h | grep '^/dev' | awk '{ printf("%s|%s\n", $6, $1) }' | sort -n >${TMP}.1
	Devices__ReportDiskParts.sh 2>>/dev/null | grep -v swap  | awk '{ printf("%s|%s|%s\n", $6, $1, $2) }' | sort -r >${TMP}.1
fi

rm -f ${TMP}.2
{
	cat ${TMP}.1 
	if [ ${SWAPS} = 1 ]
	then
		#df -h | grep '^/dev' | grep loop | awk '{ printf("%s|%s\n", $6, $1) }' | sort -r -k2 --field-separator=\|
		Devices__ReportDiskParts.sh 2>>/dev/null | grep swap  | awk '{ printf("%s|%s|%s\n", $3, $1, $2) }' | sort -r
	fi
} >${TMP}.2

rm -f ${TMP}

##FUTURES:  possible test for terminal to suppress the interactive selection of partitions when run from cron/batch.

while read line
do
	dPath=`echo "${line}" | awk -F \| '{ print $1 }' `
	echo "\n\t Perform action on partition labelled '`basename ${dPath} `' ? [y|N] => \c" >&2
	read ans <&2
	if [ -z "${ans}" ]
	then
		ans="N"
	fi

	case ${ans} in
		y* | Y* )
			echo "${line}"
			echo "\t\t Captured ${dPath} for '${FSCK}' ${dACTION} ..." >&2
			;;
		q* | Q* )
			echo "\n Bye!\n" >&2 ; exit 0
			;;
		* )
			echo "\t\t Ignored ..." >&2
			;;
	esac
done <${TMP}.2 >${TMP}

if [ ${VERB} = 1 ]
then
	echo "\n\t Data for selected work items:"
	cat ${TMP} | awk '{ printf("\t %s\n", $0 ) }'
fi

while read line
do
	echo "\n ============================================================================"
	#if [ ${VERB} = 1 ] ; then echo "\t INPUT:  ${dPath}  ${dDev}  ${dType} ..." ; fi
	if [ ${VERB} = 1 ] ; then echo "\t     INPUT:	${line} ...\n" ; fi

	dPath=`echo "${line}" | awk -F \| '{ print $1 }' `
	 dDev=`echo "${line}" | awk -F \| '{ print $2 }' `
	dType=`echo "${line}" | awk -F \| '{ print $3 }' `

	echo "\t Partition:	${dDev}	  ${dPath} \n"

	case ${dType} in
		swap )
			echo "\n\t WARNING:  Logic not defined for doing filesystem check on SWAP spaces ..."
			;;
		* )
			if [ ${REPAIR} = 1 ]
			then
				#COM="${FSCK} -fpv ${dDev}"
				COM="${FSCK} -fyv ${dDev}"
				echo "\t COMMAND:  ${COM} ..."
				${COM}
			else
				COM="${FSCK} -fnv ${dDev}"
				echo "\t COMMAND:  ${COM} ..."
				${COM}
			fi
			;;
	esac
done <${TMP}

echo "\n ============================================================================"
echo " DONE - ${thisProg}\n"

rm -f ${TMP}

exit 0
exit 0
exit 0
