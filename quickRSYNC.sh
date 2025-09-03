#!/bin/sh

####################################################################################################
###
###	$Id: quickRSYNC.sh,v 1.8 2024/07/18 02:56:26 root Exp root $
###
###	Simplified version of 'rsync' backup without the additional post-backup tasks that are performed by 'OS_Admin__partitionSecondary_Mirror.sh'.
###
####################################################################################################

yellowON="\e[93;1m"
yellowOFF="\e[0m"

redON="\e[91;1m"
redOFF="\e[0m"



	#COM="rsync --one-file-system --recursive --outbuf=Line --links --perms --times --group --owner --devices --specials --verbose --out-format=\"%t|%i|%M|%b|%f|\" ${doCheckSum} ${doUpdate} --delete-after --whole-file --human-readable --protect-args --ignore-errors --msgs2stderr ${showProgress} ./ ${PathMirror}${dirC}/ 2>${SWIP}${LogLABEL}.err | tee ${SWIP}${LogLABEL}.out"

####################################################################################################
buildBatch()
{
	#COM="rsync --one-file-system --recursive --outbuf=Line --links --perms --times --group --owner --devices --specials --verbose --out-format=\"%t|%i|%M|%b|%f|\" ${doCheckSum} ${doUpdate} --delete-after --whole-file --human-readable --protect-args --ignore-errors --msgs2stderr ./ ${PathMirror}${dirC}/"

	##	--delete-delay \
	##	--delete-after \
	##	--crtimes \
	COM="ionice -c 2 -n 7 rsync \
		${limitThruput} \
		${doUpdate} \
		${doCheckSum} \
		${showProgress} \
		--one-file-system \
		--outbuf=Line \
		--recursive \
		--delete-during \
		--preallocate \
		--links \
		--perms \
		--times \
		--group \
		--owner \
		--atimes \
		--devices \
		--specials \
		--verbose --out-format=\"%t|%i|%M|%b|%f|\" \
		--whole-file \
		--human-readable \
		--protect-args \
		--ignore-errors \
		--msgs2stderr \
		${EXCLUDES} \
		./ ${PathMirror}${dirC}/"

	START=`date`
	echo "\n\t ${START} |rsync| Start ${dirC} ..." >&2
	#cd ${PathMaster}${dirC}

	echo "
	\necho '${START} |rsync| Start ${dirC} \n\tProcess ID => '\$\$' ...' >&2
	cd ${PathMaster}${dirC}
	\n\trm -f ${SWIP}${LogLABEL}.out
	rm -f ${SWIP}${LogLABEL}.err
	{
	\n${COM}
	\necho 'START = ${START}' ; \necho '  END = '\`date\` 
	} 2>${SWIP}${LogLABEL}.err >${SWIP}${LogLABEL}.out
	RC=\$?
	\nif [ \${RC} -eq 0 ]; then
	\n\ttest -s ${STRT}${LogLABEL}.out  &&  mv -f ${STRT}${LogLABEL}.out ${STRT}${LogLABEL}.out.PREV
	test -s ${STRT}${LogLABEL}.err  &&  mv -f ${STRT}${LogLABEL}.err ${STRT}${LogLABEL}.err.PREV
	\n\tmv ${SWIP}${LogLABEL}.out ${STRT}${LogLABEL}.out
	mv ${SWIP}${LogLABEL}.err ${STRT}${LogLABEL}.err
	\nelse
	\n\tmv ${SWIP}${LogLABEL}.out ${STRT}${LogLABEL}.out.\$RC
	mv ${SWIP}${LogLABEL}.err ${STRT}${LogLABEL}.err.\$RC
	\n\tman rsync | awk -v P=\$RC '{ if( \$1 == P ){ print \$0 ; } ; }' 
	\nfi
	" >${MirrorBatch}

	chmod 700 ${MirrorBatch}
}

doReportLogs(){
	if [ ${doAllDrives} -eq 1 ]
	then
		echo "\n\n Log files:"
		ls -ltr ${PathMirror}${LogLABEL}.* | awk '{ printf("\t %s\n", $0 ) ; }'
	else
		echo "\n\n Expected Log files:"
		echo "\t ${PathMirror}${LogLABEL}.out\n\t ${PathMirror}${LogLABEL}.err\n"
	fi
} >&2


limitBandwidth()
{
	###
	###	Evaluate device speed to limit impact on other system and memory-dependent processes
	###

	if [ -s "${STRT}LIMIT__Bandwidth_rsync.txt" ]
	then
		read bandSpeed < "${STRT}LIMIT__Bandwidth_rsync.txt"
		if [ -n "${bandSpeed}" ]
		then
			if [ \( ${bandSpeed} -gt 30000 \)  -a  \( ${bandSpeed} -lt 150000 \) ]
			then
				echo "\n Using previously determined bandwidth limit for rsync buffer setting ..."
			else
				bandSpeed=""
			fi
		else
			rm -f "${STRT}LIMIT__Bandwidth_rsync.txt"
		fi
	fi

	if [ -z "${bandSpeed}" ]
	then
		echo "\n Performing speed test on backup device ..."

		rm -f "${STRT}LIMIT__Bandwidth_rsync.txt"
		### FORMAT
		#/dev/sdc4:
		# Timing O_DIRECT cached reads:    64 MB in  2.04 seconds =  31.35 MB/sec
		# Timing O_DIRECT disk reads:  98 MB in  3.06 seconds =  32.04 KB/sec
		echo "backDev = ${backDev}"

####  cat /dev/zero | pv > ${there}/junker

		devTest=`hdparm -Tt --direct ${backDev} `
		echo "${devTest}\n"

		testSpd=`echo "${devTest}" | tail -1 | awk '{ print $(NF-1), $NF ; }' `

		if [ -n "${testSpd}" ]
		then
			bandSpeed=`echo "${testSpd}" | awk '{ print $1 }' | cut -f1 -d\. `
			bandScale=`echo "${testSpd}" | awk '{ print $2 }' | cut -f1 -d/ `
			case "${bandScale}" in
				[Mm][Bb] )
					### Triple the value AND multiply by 1024
					bandSpeed=`expr ${bandSpeed} \* 6 \* 1024 / 2 `
					;;
				[Kk][Bb] )
					### Triple the value
					bandSpeed=`expr ${bandSpeed} \* 6 / 2 `
					;;
				* )
					### NULL if no recognized value
					bandSpeed=""
					;;
			esac

		fi

		if [ -n "${bandSpeed}" ]
		then
			echo "${bandSpeed}" > "${STRT}LIMIT__Bandwidth_rsync.txt"
		fi
	fi

	if [ -n "${bandSpeed}" ]
	then
		###	Set bandwidth limit for rsync to avoid flooding memory and filling swap
		limitThruput="--bwlimit=${bandSpeed}"
		echo "\n Will apply parameter to limit flooding of I/O, memory and swap ==>>  ${limitThruput}"
	else
		limitThruput=""
		echo "\n No bandwidth limiting was applied to rsync command (to prevent flooding of I/O, memory or swap) ..."
	fi
}


####################################################################################################
####################################################################################################

echo "\n\t NOTE:   This script will ONLY perform synchronization backup (applying differences).\n\t\t It does NOT perform a FULL COPY backup.\n\n\t\t For FULL COPY backup, use 'OS_Admin__partitionSecondary_Mirror.sh' responding 'y' at the appropriate prompt ...\n"

MROOT="${MROOT:-/site}"
horizLine="=============================================================================================="

thisHost=`hostname`

doCheckSum="" ; bProf="DateSize"
doUpdate=""
doShow=0
doAllDrives=0
showProgress=""
indexTypes=0
indexNames=0
bandSpeed=""

while [ $# -gt 0 ]
do
	case ${1} in
		--compareFileData )
			doCheckSum="--checksum"
			bProf="CheckSum"
			shift
			;;
		--keepNewer )
			doUpdate="--update"
			shift
			;;
		--noAction )
			doShow=1
			shift
			;;
		--doFull )
			doAllDrives=1
			shift
			;;
		--indexTypes )
			indexTypes=1
			shift
			;;
		--indexNames )
			indexNames=1
			shift
			;;
#		--monitor )
#			showProgress="--info=progress1"		## Doing this option causes multiple lines per file mirrored.
#			echo "\n\t Note:  Will report progress live ...\n"
#			shift
#			;;
		* ) echo "\n\t Unrecognized command line parameter '${1}'.  Unable to proceed.\n Bye!\n" ; exit 1
			;;
	esac
done



if [ -z "${doUpdate}" ]
then
	echo "\n\t Forcing backup of all files.       Option '--keepNewer' is available to keep backup version of files if newer ..."
fi

if [ -z "${doCheckSum}" ]
then
	echo "\n\t Checksum comparisons is disabled.  Option '--compareFileData' is available to force this check by rsync ..."
fi


case ${thisHost} in
	OasisMega1 )
		PathMaster="/"
		indent="              "
		mirrorGroup=5
		;;
#	OasisMega2 )
#		#OasisMini | OasisMidi )
#		#PathMaster="${MROOT}/"
#		#indent="        "
#		PathMaster="/"
#		indent="              "
#		mirrorGroup=7		### 7 used to avoid accidental cloberring of masterPart==8
#		;;
	* )	echo "\n\t This script is NOT to be used from this host. \n Bye!\n" ; exit 1 ;;
esac


testBK=`lsblk | grep 'disk' | grep '3.6T' `
if [ -z "${testBK}" ]
then
	echo "\n\t 4TB MyBook USB Drive is OFFLINE!  Unable to proceed.\n Bye!\n" ; exit 1
fi

echo "\n\t Following block devices have been identified:\n"
lsblk -l | awk '{ if( length($1) == 3 ){ print $0 } ; }' | awk '{ printf("\t\t %s\n", $0 ) ; }'


STRT=`pwd`

###
###	Values in list for 'masterPart' must be edited to suit the source device being backed up.
###
EXCLUDES=' --exclude=\"./cdrom/*\" --exclude=\"./dev/*\" --exclude=\"./lost+found/*\" --exclude=\"./media/*/*\" --exclude=\"./mnt/*\" --exclude=\"./mtp/*\" --exclude=\"./proc/*\" --exclude=\"./run/*\" --exclude=\"./site/*/*\" --exclude=\"./sys/*\" --exclude=\"./tmp/*\" '


first=1
for masterPart in 1 2 3 4 5 6 7 8
do
	dirC=DB001_F${masterPart}

	case ${masterPart} in
		1 )	case ${thisHost} in
				OasisMega1 )	mirrorPart=8 ;;
				#OasisMega2 )	mirrorPart=9 ;;		# 9 assigned to avoid clobbering OasisMidi
				* )	echo "\n\t Backup for this host is not configured.\n" ; exit 1 ;;
			esac
			;;
		* )	
			case ${masterPart} in
				2 | 3 | 4 | 5 | 6 | 7 )	mirrorPart=${masterPart} ;;
				8 )	if [ ${thisHost} = "OasisMega1" ]
					then
						mirrorGroup=6
						mirrorPart=1
					fi
					;;
			esac
			EXCLUDES=""
			;;
	esac

	PathMirror="${MROOT}/DB00${mirrorGroup}_F${mirrorPart}/"
	STRT="${PathMirror}"
	SWIP="${MROOT}/"

	ROOTdev=`df / | grep '/dev/sd' | awk '{ print $1 }' `
	BDbase=`basename ${PathMirror} `
	testor=`df | grep ${BDbase} | awk '{ print $1 }' `


	if [ -z "${testor}" ]
	then
		pLABEL=`echo "${PathMirror}" | cut -f3 -d/ `
		pUUID=`grep "${MROOT}/${pLABEL}" /etc/fstab | grep -v '^#' | awk '{print $1 }' | cut -f2 -d\=  `
		if [ -n "${pUUID}" ]
		then
			#echo "UUID=${pUUID}"
			pDEVICE=`findfs UUID=${pUUID} 2>>/dev/null `
			if [ -n "${pDEVICE}" ]
			then
				echo "\n\t Partition for BACKUP target '${PathMirror}' is offline ...  Cannot proceed.\n Bye!\n"
			else
				echo "\n\t Disk UUID='${pUUID}' required for BACKUP target '${PathMirror}' is not powered up ...  Cannot proceed.\n Bye!\n"
			fi	
		else
			echo "\n\t Device for ${PathMirror}' not defined in /etc/fstab ...  Cannot proceed.\n\t Please update '/etc/fstab' using info reported by 'Devices__ReportDiskParts.sh --fstab'. \n Bye!\n"
		fi
		exit 1
	fi

	if [ "${testor}" = "${ROOTdev}" ] ; then  echo "\n\t ERROR ** Target BACKUP drive '${PathMirror}' is same as ROOT drive ...  Cannot proceed.\n Bye!\n" ; exit 1 ; fi

	backDev="${testor}"

	if [ ${first} -eq 1 ]
	then
		echo "\n\t External BACKUP disk is online ..."
		first=0
	fi

	echo "\n ${horizLine}"
	echo " ==================================  PARTITION BACKUP START  =================================="
	echo " ${horizLine}\n"

	echo "\t SOURCE=${indent} ${PathMaster}${dirC}"
	echo "\t MIRROR= ${PathMirror}${dirC} ...\n"

	if [ ${doAllDrives} -eq 1 ]
	then
		doit="y"
	else
		echo "\t Proceed with backup of '${yellowON}${dirC}${yellowOFF}' ? [y|N] => \c" ; read doit
		if [ -z "${doit}" ] ; then  doit="N" ; fi
	fi

	case ${doit} in
		y* | Y* )

			echo "\n"
			test ${indexTypes} -eq 1 && echo "\t ${redON}NOTE: ${yellowON} Flag set for Partition Indexing of all File TYPES ...${yellowOFF}"
			test ${indexNames} -eq 1 && echo "\t ${redON}NOTE: ${yellowON} Flag set for Partition Indexing of all File NAMES ...${yellowOFF}"

			if [ ${masterPart} -eq 1 ]
			then
 				echo "\n\t\t Running script 'Appl__Thunderbird__CachePurge.sh' ..."
				Appl__Thunderbird__CachePurge.sh

 				echo "\n\t\t Running script 'Appl__Firefox__CachePurge.sh' ..."
				Appl__Firefox__CachePurge.sh

				echo "\n\t\t Will purge the following quantity of cache data:"
				for cacheDir in /home/ericthered/.cache/thumbnails/fail/mate-thumbnail-factory /home/ericthered/.cache/thumbnails/normal /home/ericthered/.config/ghb/EncodeLogs
				do
					###  TBD:  home/ericthered/.cache/calibre/ev2/f/
					(	cd ${cacheDir}
						du -sh ${cacheDir} 2>&1 | awk '{ printf("\t\t\t %s\n" , $0 ) ; }'
						sleep 2
						find . \( ! -type d \) -exec rm -f {} \; 
						)
				done
			fi

			if [ ${indexTypes} -eq 1 ]
			then
				OS_Admin__PartitionIndex_Make.sh --allTypes --partition "${dirC}"
			fi

			if [ ${indexNames} -eq 1 ]
			then
				UTIL__SysIndex__Build.sh --partition "${dirC}"
			fi

			if [ ! -d "${PathMirror}${dirC}" ]
			then
				mkdir "${PathMirror}${dirC}"
				if [ $RC -eq 0 ]
				then
					echo "\t NOTE:  Created directory '${PathMirror}${dirC}' ..."
					chown root:root "${PathMirror}${dirC}"
				else
					echo "\t FAILURE:  Unable to create required BACKUP directory at '${PathMirror}${dirC}'.  Abandoning!\n"
					exit 1
				fi
			fi

			LogLABEL="Z_backup.${dirC}.${bProf}"

			MirrorBatch="${STRT}${LogLABEL}.batch"
		        rm -f ${MirrorBatch}

			limitBandwidth
			#limitThruput="--bwlimit=${bandSpeed}"
			#--bwlimit=95232	### WesternDigital 4TB USB MyBook

			buildBatch

			if [ ${doShow} -eq 1 ]
			then
				echo "\n${horizLine}\nContents of intended batch script:\n\n`cat ${MirrorBatch}`\n${horizLine}\n"
			else
				rm -f ${MROOT}/Z_backup.DB00*.nohup
				nohup nice -17 ${MirrorBatch} 2>>/dev/null >${SWIP}${LogLABEL}.nohup &
				BatchPID=$!
				#echo "\n Use 'OS_Admin__partitionMirror_Monitor.sh' to monitor rsync process.\n"
				echo "\t Background 'rsync' working ..." >&2

	###
	###  FUTURES
	###
				#sleep 5
				#/usr/bin/mate-terminal -e nice -n -19 bash tail -f ${SWIP}${LogLABEL}.err &
				#/usr/bin/mate-terminal -e nice -n -19 bash tail -f ${SWIP}${LogLABEL}.out &
				#/usr/bin/mate-terminal --working-directory="${SWIP}" --command="nice -n -19 bash ( tail -f '${LogLABEL}.err' ; read k <&2 )" &
				#/usr/bin/mate-terminal --working-directory="${SWIP}" --command="nice -n -19 bash ( tail -f '${LogLABEL}.out' ; read k <&2 )" &
				
			fi

 			;;
		* )	echo "\t\t '${dirC}' skipped ..." ;;
	esac

	if [ ${doAllDrives} -eq 1 ]
	then
		case ${doit} in
			y* | Y* )
				sleep 10
				echo "\t Monitoring for completion of '${dirC}' backup running in background (PID=${BatchPID}) ..."
				#echo "\n Use 'OS_Admin__partitionMirror_Monitor.sh' to monitor rsync process.\n"

				echo "\t \c"
				interval=10
				while [ true ]
				do
					testor=`ps -ef | grep -v grep | awk -v PID="${BatchPID}" '{ if( $2 == PID ){ print $0 ; exit ; } ; }' `
					if [ -n "${testor}" ]
					then
						echo ".\c"
						sleep ${interval}
					else
						BatchPIDs="`ps -ef | grep -v 'grep' | grep rsync | awk '{ print $2 }' `"
						if [ -n "${BatchPIDs}" ]
						then
							echo "+\c"
							sleep ${interval}
						else
							break
						fi
					fi
				done

				echo "\n\t DONE\n"
				sleep 2
				doReportLogs
				echo "\n\t FAILSAFE - PID= $$  for '$0' ..."
				;;
			* ) ;;
		esac
	else
		case ${doit} in
			y* | Y* )
				doReportLogs
				echo "\n Use 'OS_Admin__partitionMirror_Monitor.sh' to monitor rsync process.\n"
				exit
				;;
			* ) ;;
		esac
	fi
done



exit 0
exit 0
exit 0
