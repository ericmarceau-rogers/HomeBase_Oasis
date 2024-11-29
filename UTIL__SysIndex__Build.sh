#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: UTIL__SysIndex__Build.sh,v 1.1 2021/11/24 13:27:01 root Exp root $
###
###	Script to create simple index list for each of directories and files for each partition on the system's boot disk.
###
####################################################################################################


##################################################################################################
##################################################################################################
doSearchIndex()
{
	if [ ! -d ${procROOT} ]
	then
		echo "\n\t Index storage location '${procROOT}' is missing.  Abandoning process.  Bye!\n" ; exit 1
	fi

	PartitionIndexD="${procROOT}/${PartitionLabel}.d.INDEX.txt"
	PartitionIndexF="${procROOT}/${PartitionLabel}.f.INDEX.txt"
	rm -f ${PartitionIndexD}
	rm -f ${PartitionIndexF}

	if [ ${doHtml} -eq 1 ]
	then
		## Logic including contents of '*.files' directories
		COMd="find -H ${SearchPath} -xdev \(   -type d \) -print >${PartitionIndexD}"
		COMf="find -H ${SearchPath} -xdev \( ! -type d \) -print >${PartitionIndexF}"
	else
		## Logic excluding contents of '*.files' directories
		COMd="find -H ${SearchPath} -xdev \(   -type d \) \( ! -name '*_files' \) -print >${PartitionIndexD}"
		#COMf="find -H ${SearchPath} -xdev \( ! -type d \) \( ! -regex '*_files/*' \) -print >${PartitionIndexF}"
		COMf="find -H ${SearchPath} -xdev \( ! -type d \) -print | grep -v '_files/' >${PartitionIndexF}"
	fi

	echo "  DOING directories:\n   ${COMd} ..."
	eval ${COMd}

	mv	${PartitionIndexD}    ${PartitionIndexD}2
	sort	${PartitionIndexD}2  >${PartitionIndexD}
	rm -f	${PartitionIndexD}2
	ls -l ${PartitionIndexD} 2>&1 | awk '{ printf("   %s\n", $0 ) ; }'

	echo "  DOING files:\n   ${COMf} ..."
	eval ${COMf}

	mv	${PartitionIndexF}    ${PartitionIndexF}2
	sort	${PartitionIndexF}2  | grep '^/' >${PartitionIndexF}
	rm -f	${PartitionIndexF}2
	ls -l ${PartitionIndexF} 2>&1 | awk '{ printf("   %s\n", $0 ) ; }'
}	#doSearchIndex()


##################################################################################################
##################################################################################################
askDoDrive()
{
	echo "\n Rebuild partition index for partition ${PartitionLabel} ? [y|N] => \c"
	read ans

	if [ -z "${ans}" ]
	then
		ans="N"
	fi

	case ${ans} in
		y* | Y* ) 	doList="${doList} ${PartitionLabel}"
				#doThis="Y"
				;;
		* )		#doThis="N"
				;;
	esac
}	#askDoDrive()


##################################################################################################
##################################################################################################
##################################################################################################

TMP=/tmp/tmp.`basename $0 ".sh" `.$$

doHtml=0
rebuild=0
doList=""

while [ $# -gt 0 ]
do
	case $1 in
		--partition )	doList="${2}" ; echo "\n\n STARTING:  $0 ...\n" ; shift ; shift ;;
		--htmlFILES )	doHtml=1	; shift ;;
		--rebuildALL )	rebuild=1	; shift ;;
		* ) echo "\n\t Invalid parameter used on command line.  Only options allowed: [ --htmlFILES | --rebuildALL ] \n" ; exit 1 ;;
	esac
done

case `hostname` in
	OasisMega1 )
		procROOT="/DB001_F2/LO_Index"
		PartitionLabel=DB001_F1
		indexMode=2
		;;
	OasisMega2 )
		procROOT="/LO_Index"
		PartitionLabel=DB002_F1
		SearchPath=/
		indexMode=1
		;;
#	OasisMidi )
#		procROOT="/LO_Index"
#		PartitionLabel=DB003_F1
#		SearchPath=/
#		indexMode=1
#		;;
#	OasisMini )
#		procROOT="/LO_Index"
#		PartitionLabel=DB004_F1
#		SearchPath=/
#		indexMode=1
#		;;
	* ) echo "\n\t Logic has not been defined to preform indexing for this host.\n Bye!\n" ; exit 1 ;;
esac

cd /
count=`ls -d DB00?_F? 2>>/dev/null | wc -l | awk '{ print $1 }' `

if [ ${rebuild} -eq 1 ]
then
	rm -f ${TMP}.listDirIndexes 2>>/dev/null ; ls ${procROOT}/DB00?_F?.d.INDEX.txt   >${TMP}.listDirIndexes 2>>/dev/null
	rm -f ${TMP}.listFilIndexes 2>>/dev/null ; ls ${procROOT}/DB00?_F?.f.INDEX.txt   >${TMP}.listFilIndexes 2>>/dev/null
fi

if [ -s ${TMP}.listDirIndexes ] ; then  rm -fv `cat ${TMP}.listDirIndexes ` ; fi
if [ -f ${TMP}.listFilIndexes ] ; then  rm -fv `cat ${TMP}.listFilIndexes ` ; fi

if [ -z "${doList}" ]
then
	for PartitionLabel in DB00?_F?
	do
		askDoDrive
	done
fi

echo "\n Worklist:  ${doList} ...\n"

for PartitionLabel in `echo ${doList} `
do
	SearchPath=/${PartitionLabel}

	case ${PartitionLabel} in
		#DB001_F1 | DB002_F1 | DB003_F1 | DB004_F1 )
		DB001_F1 | DB002_F1 )
			SearchPath=/
			#askDoDrive

			#if [ "${doThis}" = "Y" ]
			#then
				echo "\n Evaluating for ${PartitionLabel} ..."

				doSearchIndex
			#fi
			;;
		* )	
			#askDoDrive

			#if [ "${doThis}" = "Y" ]
			#then
			#	echo "\n\t Suppressed indexing of ${PartitionLabel} as chosen ..."
			#else
				test1=`df -h / | grep '/dev' | awk '{ print $1 }' `
				test2=`df -h ${SearchPath} | grep '/dev' | awk '{ print $1 }' `

				if [ "${test1}" = "${test2}" ]
				then
					echo "\n\t Suppressed indexing of ${PartitionLabel} as same partition as root ..."
				else
					echo "\n Evaluating for ${PartitionLabel} ..."

					doSearchIndex
				fi
			#fi
			;;
	esac
done

echo ""
rm -f ${TMP}.listDirIndexes 2>>/dev/null ; ls ${procROOT}/DB00?_F?.d.INDEX.txt   >${TMP}.listDirIndexes 2>>/dev/null

if [ -s ${TMP}.listDirIndexes ]
then
	echo " Creating combined global INDEX (directories) ..."
	rm -fv ${procROOT}/INDEX.allDrives.d.txt 2>&1 | awk '{ printf("   %s\n", $0 ) ; }'
	echo "   Old directory index purged ..."
	cat ${procROOT}/DB00?_F?.d.INDEX.txt   >${procROOT}/INDEX.allDrives.d.txt
	echo "   New global directory index created ..."
	ls -l ${procROOT}/INDEX.allDrives.d.txt 2>&1 | awk '{ printf("   %s\n", $0 ) ; }'
else
	echo " ERROR:  No directory index files for individual partitions.  Please investigate.\n" ; exit 1
fi

echo ""
rm -f ${TMP}.listFilIndexes 2>>/dev/null ; ls ${procROOT}/DB00?_F?.f.INDEX.txt   >${TMP}.listFilIndexes 2>>/dev/null

if [ -s ${TMP}.listFilIndexes ]
then
	echo " Creating combined global INDEX (files) ..."
	rm -fv ${procROOT}/INDEX.allDrives.f.txt 2>&1 | awk '{ printf("   %s\n", $0 ) ; }'
	echo "   Old file index purged ..."
	cat ${procROOT}/DB00?_F?.f.INDEX.txt   >${procROOT}/INDEX.allDrives.f.txt
	echo "   New global file index created ..."
	ls -l ${procROOT}/INDEX.allDrives.f.txt 2>&1 | awk '{ printf("   %s\n", $0 ) ; }'
else
	echo " ERROR:  No file index files for individual partitions.  Please investigate.\n" ; exit 1
fi

echo "\n DONE!\n"

rm -f ${TMP}.listDirIndexes ${TMP}.listFilIndexes

exit 0
exit 0
exit 0


###############################################################################
###############################################################################
###############################################################################


