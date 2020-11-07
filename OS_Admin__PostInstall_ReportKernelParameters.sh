#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: OS_Admin__PostInstall_ReportKernelParameters.sh,v 1.2 2020/08/19 21:04:51 root Exp $
###
###	This script will generate a report of the KERNEL parameters and settings. 
###
####################################################################################################

##FIRSTBOOT##

STRT="${HOME}"
BASE=`basename "$0" ".sh" `
TMP=/tmp/${BASE}


#INTERFACE="enp2s0"
#parmPATH="/proc/sys/net/ipv4/conf"
#cd ${parmPATH}/${INTERFACE}


procSysRoot="/proc/sys"
cd ${procSysRoot}


rm -f ${TMP}.branch

for branch in *
do
	if [ -d ${branch} ]
	then
		echo "${branch}"
	fi
done >${TMP}.branch

for branch in `cat ${TMP}.branch `
do
	echo "\n Scanning under ${procSysRoot}/${branch} ..."


	rm -f ${TMP}.dirs

	cd ${procSysRoot}

	find ${branch} -type d -print | sort >${TMP}.dirs

	REPORT="${STRT}/${BASE}_${branch}"

	rm -f ${REPORT}.pretty*
	rm -f ${REPORT}.parmset*


	while read dir
	do
		parmPATH="/proc/sys/${dir}"
		cd ${parmPATH}

		echo "\t Examining ${parmPATH} ..."

		rm -f ${TMP}.fils

		for file in *
		do
			if [ ! -d ${file} ]
			then
				echo ${file}
			fi
		done >${TMP}.fils

		if [ -s ${TMP}.fils ]
		then
			parmPREF=`echo ${dir} | sed 's+\/+\.+g' `
			echo "\n#===============================================================================================================\n# DIR = /proc/sys/${dir}\n" >>${REPORT}.pretty.tmp

			wide=`cat ${TMP}.fils | while read line ; do  echo "${line}" | awk '{ l=length($0) ; print l ; }' ; done | sort -nr | head -1 `

			for file in `cat ${TMP}.fils `
			do
				parmLBL=${file}
				parmVAL=`cat ${file} 2>>/dev/null`

				if [ -w ${file} ]
				then
					parmWRITE=1 ; noRESTORE="            " 
				else
					parmWRITE=0 ; noRESTORE="#READ-ONLY# " 
				fi

				if [ -z "${parmVAL}" ]
				then
					parmVAL="**_ACCESS_TO_PARAMETER_VALUE_NOT_PERMITTED_**"
					parmWRITE=0 ; parmREAD=0 ; noRESTORE="#NO-ACCESS# " 
				else
					###	Logic to handle multi-line value for '/proc/sys/dev/cdrom/info'

					parmLIN=`echo "${parmVAL}" | wc -l | awk '{ print $1 }' ` 
					if [ ${parmLIN} -eq 1 ]
					then
						parmMULT=0 ; moreDETAILS=""
					else
						parmVAL=`echo "${parmVAL}" | head -1 `
						parmMULT=1 ; moreDETAILS="\t\t# [Use  'cat `pwd`/${file}' to see additional details]"
					fi
				fi

				echo "${parmLBL} ${parmVAL}" | awk -v WIDE="${wide}" -v REST="${noRESTORE}" -v MORE="${moreDETAILS}" '{ WIDE=WIDE+3 ; fmt="%s%-"WIDE"s = %11s%s\n" ; printf(fmt, REST, $1, $2, MORE ) ; }'
			done | awk '{ printf("\t%s\n", $0 ) ; }' >>${REPORT}.pretty.tmp

			echo "\n#===============================================================================================================\n# DIR = /proc/sys/${dir}\n" >>${REPORT}.parmset.tmp
			for file in `cat ${TMP}.fils `
			do
				parmLBL=${file}
				parmVAL=`cat ${file} 2>>/dev/null`

				if [ -w ${file} ]
				then
					parmWRITE=1 ; noRESTORE="" 
				else
					parmWRITE=0 ; noRESTORE="#READ-ONLY# " 
				fi

				if [ -z "${parmVAL}" ]
				then
					parmVAL="**_ACCESS_TO_PARAMETER_VALUE_NOT_PERMITTED_**"
					parmWRITE=0 ; parmREAD=0 ; noRESTORE="#NO-ACCESS# " 
				else
					###	Logic to handle multi-line value for '/proc/sys/dev/cdrom/info'

					parmLIN=`echo "${parmVAL}" | wc -l | awk '{ print $1 }' ` 
					if [ ${parmLIN} -eq 1 ]
					then
						parmMULT=0 ; moreDETAILS=""
					else
						parmVAL=`echo "${parmVAL}" | head -1 `
						parmMULT=1 ; moreDETAILS="   # [Use  'cat `pwd`/${file}' to see additional details]"
					fi
				fi

				echo "${noRESTORE}${parmLBL} = ${parmVAL}${moreDETAILS}"
			done >>${REPORT}.parmset.tmp
		fi
	done <${TMP}.dirs

	echo " Scanning complete.\n"

	if [ -s ${REPORT}.pretty.tmp ]
	then
		echo "################################################################################################################"  >${REPORT}.pretty
		echo "###	Formatted report of KERNEL settings under /proc/sys/${branch}' [`date`]"                                >>${REPORT}.pretty
		echo "################################################################################################################" >>${REPORT}.pretty
		cat ${REPORT}.pretty.tmp >>${REPORT}.pretty
	fi
	if [ -s ${REPORT}.parmset.tmp ]
	then
		echo "################################################################################################################"  >${REPORT}.parmset
		echo "###	Restore image of KERNEL settings under /proc/sys/${branch}' [`date`]"                                   >>${REPORT}.parmset
		echo "################################################################################################################" >>${REPORT}.parmset
		cat ${REPORT}.parmset.tmp >>${REPORT}.parmset
	fi

	rm -fv ${TMP}.dirs
	rm -fv ${TMP}.fils
	rm -fv ${REPORT}.pretty.tmp
	rm -fv ${REPORT}.parmset.tmp
	echo ""

	ls -l ${REPORT}.*
	echo ""

done <${TMP}.branch

exit 0
exit 0
exit 0
