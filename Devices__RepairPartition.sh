#!/bin/sh

###############################################################################################
###
###	$Id: Devices__RepairPartition.sh,v 1.4 2024/06/09 16:42:56 root Exp $
###
###	Script to perform e2fsck, optionally in repair mode to identify badblocks and take those out of availability list for the filesystem.  Fully-formed explicit command for action is offered up.  That command must then be manually run from the shell prompt.
###
###############################################################################################

#STATUS=PROD
#set -x


TMP=/tmp/`basename $0 ".sh" `.tmp


###############################################################################################
###############################################################################################
offerRepair()
{
	if [ "${mountStat}" = "Mounted" ]
	then 
		echo "\t Partition '${thisPart}' is still mounted. \n\t\t Do 'un-mount' for fsck ? [y|N] => \c"
		read ans <&2
		if [ -z "${ans}" ] ; then  ans="N" ; fi

		case ${ans} in
			y* | Y* )
				mountPATH=`echo "${line}" | awk -v part=${thisPart} '( part == $3 ){ print $6 }' `
				echo "\t\t\t umount -v ${mountPATH} ..."
				umount -v ${mountPATH} 2>&1 | awk '{ printf("\t\t\t %s\n", $0 ) }'
				doRepair=1
				;;
			* )
				echo "\t\t Skipped ...\n"
				doRepair=0
				;;
		esac
	else
		echo "\t Partition '${thisPart}' is offline."
		doRepair=1
	fi

	if [ ${doRepair} -eq 1 ]
	then
		echo "\t\t Perform fsck repair on '${thisPart}' ? [y|N] => \c"
		read ans <&2
		if [ -z "${ans}" ] ; then  ans="N" ; fi

		case ${ans} in
			y* | Y* )
				
				if [ -z "${badBlocks}" ] ; then echo "\n\t NOTE:  Option '--badblocks' is available but, if used, 'e2fsck' could take aprox 2 hours ..." ; fi
				case ${thisPart} in
					DB004_F? | DB003_F? ) BlockSize="-B 512" ;;
					DB005_F? | DB006_F? | DB002_F? | DB001_F? ) BlockSize="-B 4098" ;;
					* ) echo "\t WARNING: Undocumented Device, block size unknown, using default 512 bytes ..." ; BlockSize="" ;;
				esac

				DirectIO="-D"
				badBlocksReport="BadBlocks_Report_${thisPart}.badblocks"
				# badblocks -v ${thisDev} >${badBlocksReport}
				COM="e2fsck  ${DirectIO} ${fsckVerbose} ${force} ${badBlocks} ${autoYesResponse} ${progress} ${BlockSize} ${thisDEV}"
				COM="${COM} >${badBlocksReport} 2>${badBlocksReport}.err"

				echo "\t\t Run the following command at the command line:\n\n\t => ${COM}"
				echo "\n\t\t To reclaim the list of bad blocks, use:  dumpe2fs -b ${thisDEV} \n Exiting script.\n"

				#  3699   2618  /0 root     ......... e2fsck -v -f -k -cc -y -C 2 -B 512 /dev/sdd2
				#  3700   3699  /0 root     .......... sh -c badblocks -b 4096 -X -s -n /dev/sdd2 28780446
				#  3701   3700  /0 root     ........... badblocks -b 4096 -X -s -n /dev/sdd2 28780446

				# Testing with random pattern: ^C3.99% done, 52:08 elapsed. (0/0/0 errors)
				# Interrupted at block 6906112

				exit 0

				;;
			* )
				echo "\t\t Skipped ...\n"
				;;
		esac
	fi
}


###############################################################################################
###############################################################################################

debug=0
verbose=0
badBlocks=""
progress="-C 2"

while [ $# -gt 0 ]
do
	case $1 in
		--debug )		debug=1 ; shift ;;
		--verbose)		verbose=1 ; shift ;;
		--badblocks_new )	badBlocks="-cc" ; shift ;;
		--badblocks_keep )	badBlocks="-k -cc" ; shift ;;
		* )	echo "\n\t Invalid parameter $1 used on command line.\n Bye! \n" ; exit 1 ;;
	esac
done

if [ ${debug} -eq 0 ]    ; then  echo "\n\t NOTE:  Option '--debug' is available to report details which are normally kept in the background ..." ; fi
if [ ${verbose} -eq 0 ]  ; then  echo "\n\t NOTE:  Option '--verbose' is available to provide in-process visibility of some information/decisions ..." ; fi
if [ -z "${badBlocks}" ] ; then  echo "\n\t NOTE:  Option '--badblocks_new' or '--badblocks_keep' are available but, if used, 'fsck' could take aprox 3 hours ..." ; fi
echo ""

fsckVerbose="-v"
force="-f"
autoYesResponse="-y"

rootDEV=`df / | grep '/dev' | awk '{ print $1 }' `
workDEV=`df . | grep '/dev' | awk '{ print $1 }' `
if [ -n "${admin}" ] ; then  adminDEV=`df ${admin} | grep '/dev' | awk '{ print $1 }' ` ; else  adminDEV="" ; fi

if [ ${debug} -eq 1 ] ; then  echo "\t    workDEV= ${workDEV} ..." ; echo "\t   adminDEV= ${adminDEV} ..." ; fi

comParts="Devices__ReportDiskParts.sh"
tester=`which ${comParts} `

if [ -z "${tester}" ] ; then  echo "\n\t Unable to locate required script '${comParts}'.  Process abandoned. \n\n Bye!\n" ; exit 1 ; fi

${comParts} 2>>/dev/null | grep -v 'swap' | sort -k3 >${TMP}.details

###	Report Format:
#/dev/sda1    ext4     DB004_F1   35e8b30a-bd60-4648-a101-e502f866bc05   Mounted       /site/DB004_F1
#/dev/sda2    swap     DB004_S1   baaf58d0-df6a-4967-89ea-739b34840530   Enabled       [SWAP]

awk -v root=${rootDEV} '{ if( $1 != root ) print $3 }' < ${TMP}.details >${TMP}.parts

if [ ${debug} -eq 1 ] ; then  echo "\n\t Contents of '${TMP}.details':\n" ; cat ${TMP}.details ; echo "" ; fi

if [ ${verbose} -eq 1 ] ; then  echo "\n\t Contents of '${TMP}.parts':\n" ; cat ${TMP}.parts ; echo "" ; fi

while read line
do
	thisPart=`echo "${line}" | awk -v root=${rootDEV} '{ if( $1 != root ) print $3 }' `

	if [ -n "${thisPart}" ]
	then
		thisDEV=`echo "${line}" | awk '{ print $1 }' `
		mountStat=`echo "${line}" | awk -v part=${thisPart} '( part == $3 ){ print $5 }' `

		if [ ${debug} -eq 1 ] ; then  echo "\t    thisDEV= ${thisDEV} ..." ; fi
		if [ ${debug} -eq 1 ] ; then  echo "\t  mountStat= ${mountStat} ..." ; fi

		if [ "${thisDEV}" = "${adminDEV}" ]
		then
			echo "\t Skipping partition '${thisPart}'.  Unable to attempt repair on partition containing active software libraries ...\n"
		else
			if [ "${thisDEV}" = "${workDEV}" ]
			then
				echo "\t Skipping partition '${thisPart}'.  Unable to attempt repair on live partition (current working directory) ...\n"
			else
				offerRepair
			fi
		fi
	else
		echo "\t Skipping root partition, '`grep ${rootDEV} ${TMP}.details | awk -v root=${rootDEV} '( root == $1 ){ print $3 }' `'.  Unable to attempt repair on live partition ...\n"
	fi
done <${TMP}.details


exit 0
exit 0
exit 0


