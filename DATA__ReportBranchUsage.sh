#!/bin/sh

###########################################################################################
###
###	$Id: DATA__ReportBranchUsage.sh,v 1.5 2022/08/17 19:09:19 root Exp $
###
###	Script to generate report for selected partition, providing disk usage under each top-level directory on that partition.
###
###########################################################################################

doThisPart()
{
	if [ "${DISKmount}" = "/" ] ; then  excludeDirs="! -name proc ! -name run" ; fi

	REPORT="${STRT}/${BASE}_${DISKlabel}.txt"
	COM="find . -maxdepth 1 -xdev -type d ${excludeDirs} ! -name . -exec du --one-file-system -sh '{}' \; | sort -hr "

	echo "\t Doing:  ${COM} ..."

	( cd ${DISKmount} ; eval ${COM} ) |
		awk -v label="${DISKlabel}" '{	if( $1 == "0" ){
				outVal=$1 ;
				outUnt="" ;
			}else{
				n=length( $1 ) ;
				outVal=substr( $1, 1, n-1 ) ;
				outUnt=substr( $1, n ) ;
			} ;
			temp=substr( $2, 3 ) ;
			printf("%8.1f %1s  /%s/%s\n", outVal, outUnt, label, temp ) ;
		}' >${REPORT}

	ls -l ${REPORT}
}


###############################################################################################
###############################################################################################


doAll=0
if [ "$1" = "--all" ] ; then  doAll=1 ; fi

BASE=`basename "$0" ".sh" `
TMP=/tmp/${BASE}.tmp
STRT=`pwd`

PartList="${TMP}.parts"

Devices__ReportDiskParts.sh 2>>/dev/null | grep -v 'swap' | grep -v 'Not_Mounted' | sort -r --key 3 >${PartList}

###	Report Format:
#/dev/sdb1    ext4     DB001_F1   f56b6086-229d-4c17-8a5b-e68de1a4e73d   Mounted       /DB001_F1
#/dev/sdc3    ext4     DB003_F1   1a3ab410-2639-44aa-b0ca-72da4f8027e8   Not_Mounted   /site/DB003_F1
#/dev/sda1    swap     DB004_S1   22da1040-af94-4767-becf-aa9aa400f8f2   Enabled       [SWAP]
#/dev/sdb3    swap     DB001_S1   c37e53cd-5882-401c-8ba3-172531a082e9   Not_Enabled   [SWAP_OFFLINE]

cat ${PartList} | awk '{ print $3, $6 }' |
while [ true ]
do
	read DISKlabel DISKmount
	if [ -z "${DISKlabel}" ] ; then  echo "" ; exit 0 ; fi

	if [ ${doAll} -eq 1 ]
	then
		doThisPart
	else
		echo "\n\t Perform disk usage scan on partition ${DISKlabel} ? [y|N] => \c" >&2
		read doit <&2

		if [ -z "${doit}" ] ; then  doit="N" ; fi

		case ${doit} in
			y* | Y* ) doThisPart ;;
			* )	;;
		esac
	fi
done


exit 0
exit 0
exit 0


