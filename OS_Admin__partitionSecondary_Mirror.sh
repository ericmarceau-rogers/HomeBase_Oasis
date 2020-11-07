#!/bin/sh
#DevStat=PROD

procROOT="/DB001_F2"

############################################################################################################
############################################################################################################
#
#	$Id: OS_Admin__partitionSecondary_Mirror.sh,v 1.10 2019/09/02 04:12:59 root Exp $
#
############################################################################################################
############################################################################################################

##############################################################################
##############################################################################
###
### Program to mirror a selection from a pre-defined 
###    set of partitions (a.k.a.  directory trees)
###
### Program will prompt user to pick selection from the list offered
###
### Program will flag existence of ${dir}/PARTITION_LOCK as flag
###    preventing mirroring of partition to avoid cloberring files
###    which may have been maintained in the Mirror rather than the Master.
###
##############################################################################
##############################################################################

##############################################################################
##############################################################################
###
###	Subroutine Functions
###

###
### Offer option to user at runtime to choose backup managing/showing changes 
### to filesystem or simply move old backup image aside and to straight backup
### to blank target directory.
###
Option_TrackChanges()
{

	echo "\n\t Backup Logging Options\n
	\t 1 - Show all changes per 'rsync' standard nomenclature
	\t 2 - Show only image captured of Master [default] \n
	 Enter selection => \c"
	read yy
	if [ "${yy}" = "" ]
	then	yy="2"
	fi

	case ${yy} in
		1 )	TRKCHG="y"
			;;
		* )	TRKCHG="n"
			;;
	esac
}



###
### give list of all partitions on host, as reported by df
###
getPartList()
{
	# Get list of non-root partitions in order of increasing used data size.

	ArchData="${procROOT}/OasisCommon/00_00_Oasis_SystemArchitecture"

	datfil="${ArchData}/${Master}_PartitionTable.txt"

	if [ ! -f ${datfil} ]
	then
		echo "\n\t Missing partition data table.  Unable to proceed.\n"
		exit 1
	fi

	pref=`grep '/dev' ${datfil} | cut -f2 -d\| | cut -f2 -d\= `
	root=`df / | awk '{print $1}' | grep '/dev' `
	
 #=#	if [ `hostname` = "OasisMega1" ]
 #=#	then
 #=#		echo ${FirstPart}
 #=#	fi
 #=#	df -h | grep ${pref} | grep -v ${root} | sort -n -k3.1,3.4 | awk '{print $6}' | cut -c2- | sort

	cut -f2 -d\| ${datfil} | grep '_F' 
}	




###
### generate 'stat' function report for all files on partitions that were backed up
###
getSrcStatReport()
{
	( cd /${dirC}

	while read line
	do
		eval stat --format=\"\|\%F\|\%y\|\%a\|\%U\|\%G\|\%s\|\%n\|\" \"${line}\"
	done <${STRT}/${dirC}.z1
	) >${PathMirror}${dirC}.rsync.stat.src  2>${PathMirror}${dirC}.rsync.stat.src.err

	### Track filenames which special characters
	grep \' ${STRT}/${dirC}.z1 | tee ${STRT}/${dirC}.z1.quotes	>${PathMirror}${dirC}.rsync.quotes
	grep \| ${STRT}/${dirC}.z1 | tee ${STRT}/${dirC}.z1.bar		>${PathMirror}${dirC}.rsync.bar
	grep \+ ${STRT}/${dirC}.z1 | tee ${STRT}/${dirC}.z1.plus	>${PathMirror}${dirC}.rsync.plus
	grep \% ${STRT}/${dirC}.z1 | tee ${STRT}/${dirC}.z1.percent	>${PathMirror}${dirC}.rsync.percent
	grep \@ ${STRT}/${dirC}.z1 | tee ${STRT}/${dirC}.z1.ampers	>${PathMirror}${dirC}.rsync.ampers
}


purgeDefunctDirs(){
##############################################################################
##############################################################################
###
###	Section 3a:	Locate defunct directories to purge before rsync
###

	echo "\n `date` |Defunct Dirs| Start ${dirC} ..."

	echo "\t Creating list of directories in Mirror to compare for purge prior to rsync ..."

	cd ${PathMirror}${dirC}

	find . -type d -print | sort --reverse > ${STRT}/dirsMirror.${dirC}.dlist

	cd ${PathMaster}${dirC}

	rm -f ${STRT}/dirsMirror.${dirC}.defunctD
	touch ${STRT}/dirsMirror.${dirC}.defunctD

	while read line
	do
		if [ ! -d "${line}" ]
		then
			echo "${line}"
		fi
	done < ${STRT}/dirsMirror.${dirC}.dlist  > ${STRT}/dirsMirror.${dirC}.defunctD

	echo "\n\t Opening list of directories to be purged for viewing and possible manual editing, before purging ..."
	echo "\t Hit return to continue with editing ...\c"
	read k

	vi ${STRT}/dirsMirror.${dirC}.defunctD

	if [ -s ${STRT}/dirsMirror.${dirC}.defunctD ]
	then
		cd ${PathMirror}${dirC}

		echo "\t Purging directories identified as defunct for current image ..."
		while read line
		do
			rm -rf --verbose --one-file-system "${line}"		
		done <${STRT}/dirsMirror.${dirC}.defunctD
	else
		echo "\t No directories identified for purging ..."
	fi
}


purgeDefunctFils(){
##############################################################################
##############################################################################
###
###	Section 3b:	Locate defunct files to purge before rsync
###

	echo "\n `date` |Defunct Files| Start ${dirC} ..."

	echo "\t Creating list of files in Mirror to compare for purge prior to rsync ..."

	cd ${PathMirror}${dirC}

	find . -type f -print | sort > ${STRT}/dirsMirror.${dirC}.flist

	cd ${PathMaster}${dirC}

	rm -f ${STRT}/dirsMirror.${dirC}.defunctF
	touch ${STRT}/dirsMirror.${dirC}.defunctF

	while read line
	do
		if [ ! -f "${line}" ]
		then
			echo "${line}"
		fi
	done < ${STRT}/dirsMirror.${dirC}.flist  >${STRT}/dirsMirror.${dirC}.defunctF

	echo "\n\t Opening list of files to be purged for viewing and possible manual editing, before purging ..."
	echo "\t Hit return to continue with editing ...\c"
	read k

	vi ${STRT}/dirsMirror.${dirC}.defunctF

	if [ -s ${STRT}/dirsMirror.${dirC}.defunctF ]
	then
		cd ${PathMirror}${dirC}

		echo "\t Purging files identified as defunct for current image ..."
		while read line
		do
			rm -f "${line}"		
		done <${STRT}/dirsMirror.${dirC}.defunctF
	else
		echo "\t No files identified for purging ..."
	fi
}
##############################################################################
##############################################################################
###
###	Main Program
###

clear

TMP=/tmp/tmp.`basename $0 ".sh"`.$$

while [ $# -gt 0 ]
do
	case ${1} in
		-monitor )
			showProgress="--info=progress1"
			echo "\n\t Note:  Will report progress live ...\n"
			shift
			;;
	esac
done

Option_TrackChanges


echo "\n\t N.B.  OasisMega1  is 'Master Host' ...\n\t\t ... and OasisMega2 is 'Mirror Host' ..."


###
###	Section 1:	Host-specific settings
###

checkDir()
{
	#echo PathMaster   = ${PathMaster}
	#echo PathMirror  = ${PathMirror}

	for dirA in ${PathMaster} ${PathMirror}
	do
		if [ ! -d ${dirA} ]
		then
			echo "\n\t ${dirA} is not mounted!\n\t Task ABANDONNED!\n"
			exit 1
		fi
	done
}

STRT=`pwd`
Master=OasisMega1
Mirror=OasisMega2

case `hostname` in
	OasisMega1 )
		PathMaster="/"
		PathMirror="/media/ericthered/DB002_F1/"

		checkDir

		test1=`df -h ${PathMaster} | grep '/dev' | awk '{ print $1 }' `
		test2=`df -h ${PathMirror} | grep '/dev' | awk '{ print $1 }' `

		if [ "${test1}" = "${test2}" ]
		then
			echo "\n\t Mirror drive not mounted at '${PathMirror}'.  Abandoning for Administrator correction of required partition.\n"
			exit 1
		fi
		;;
	OasisMega2 )
		# echo "\n  This tool has not been fully adapted for host `hostname`.\n" ; exit
		PathMaster="/media/ericthered/DB001_F2/"
		PathMirror="/"

		checkDir

		test1=`df -h ${PathMaster} | grep '/dev' | awk '{ print $1 }' `
		test2=`df -h ${PathMirror} | grep '/dev' | awk '{ print $1 }' `

		if [ "${test1}" = "${test2}" ]
		then
			echo "\n\t Master drive not mounted at '${PathMaster}'.  Abandoning for Administrator correction of required partition.\n"
			exit 1
		fi
		;;
	* )
		echo "\n\t This script is not intended for use on this host.\n"
		exit 0
		;;
esac



##############################################################################
##############################################################################
###
###	Section 2:	Choosing scope of backup, selection of partitions
###

doList=""

for dirB in `getPartList `
do
	if [ -d ${PathMaster}${dirB} ]
	then
		if [ -f ${PathMaster}${dirB}/PARTITION_LOCK ]
		then
			echo "\t Sorry.  Action blocked by existence of 'PARTITION_LOCK' file on the partition.\n\t Mirror or this partition is protected for review and action by administrator..."
			ls -l ${PathMaster}${dirB}/PARTITION_LOCK
		else
			echo "\n\t Mirror partition '${dirB}' ? [y|N] => \c"
			read ans

			case ${ans} in
				y* | Y* )
					doList="${doList} ${dirB}"
					echo "\t\t will be done ..."
					;;
				* )
					echo "\t\t ignored ..."
					;;
			esac
		fi
	else
		echo "\t Sorry.  That partition is not mounted or available for backup.\n\t Contact administrator for corrective intervention ASAP ..."
	fi
done


if [ -z "${doList}" ]
then
	echo "\t No items selected.  Task abandoned intentionally.\n"
	exit 1
else
    for dirC in   `echo ${doList}`
    do

	if [ \( -n "${FirstPart}" \) -a \( "${dirC}" != "${FirstPart}" \) ]
	then 
		echo "\n\t Taking 4 minute pause for CPU and hardware cooldown ..."
		sleep 240 ; 
	fi
	
	ABC=/tmp/`basename $0 ".sh"`.tmp
	#ABC=${procROOT}/OasisCommon/DEBUG_`basename $0 ".sh"`.`date +%Y%m%d-%H%M`.tmp

#logicBypass

	echo "\n\t Override - Forced Logic ..." >${ABC}

	if [ ! -s ${ABC} ]
	then
		echo "\n\t There are no new files or changes on this partition requiring backup with rsync ..."
	else
 		if [ -z "${FirstPart}" ]
		then
			FirstPart="${dirC}"
		fi


		### IMPORTANT ###  Suppressed until this logic can produce more dependable results for automated process.
		#purgeDefunctDirs

		### IMPORTANT ###  Suppressed until this logic can produce more dependable results for automated process.
		#purgeDefunctFils

		if [ -d ${PathMirror}${dirC}-B2 ]
		then
			rm -rf ${PathMirror}${dirC}-B2
			echo "\n\t PURGED:  '${PathMirror}${dirC}-B2' ..."
		fi

		if [ \( -d ${PathMirror}${dirC} \) -a \( ${TRKCHG} = "n" \) ]
		then
			mv ${PathMirror}${dirC} ${PathMirror}${dirC}-B2
			echo "\n\t Previous backup image:	'${PathMirror}${dirC}'\n\t\t      Moved to:	'${PathMirror}${dirC}-B2' ..."
		fi

		if [ ! -d ${PathMirror}${dirC} ]
		then
			mkdir ${PathMirror}${dirC}
		fi

		if [ ! -d ${PathMirror}${dirC} ]
		then
			echo "\n\t Unable to create root directory for backup image at '${PathMirror}${dirC}' !!!\n\t ADMINISTRATOR CORRECTION REQUIRED.\n\t Abandoning backup process.  Bye!\n" ; exit 1
		fi


##############################################################################
##############################################################################
###
###	Section 3c:	Run backup job
###

		echo "\n `date` |rsync| Start ${dirC} ..."

		cd ${PathMaster}${dirC}

		#nice -17 rsync \
		rsync \
		--one-file-system \
		--recursive \
		--links \
		--perms \
		--times \
		--group \
		--owner \
		--devices \
		--specials \
		--verbose	--out-format="%t|%i|%M|%b|%f|" \
		--update	--checksum \
		--delete-during \
		--whole-file \
		--human-readable \
		--protect-args \
		--ignore-errors \
		--msgs2stderr \
		${showProgress} \
		./	${PathMirror}${dirC}/	 2>${STRT}/Z_backup.${dirC}.err | tee ${STRT}/Z_backup.${dirC}.out


		if [ -f ${STRT}/Z_backup.${dirC}.out ]
		then
			cp -f ${STRT}/Z_backup.${dirC}.out ${PathMirror}${dirC}.rsync.log

			rm -f ${TMP}
			diff ${STRT}/Z_backup.${dirC}.out ${PathMirror}${dirC}.rsync.log >${TMP}
			if [ -s ${TMP} ] 
			then
				echo "\t Discrepency found between  ${STRT}/Z_backup.${dirC}.out  and  ${PathMirror}${dirC}.rsync.log .\n"
			else
				rm -f ${STRT}/Z_backup.${dirC}.out
 				echo "\t Log file for ${dirC} saved:		${PathMirror}${dirC}.rsync.log ..."
			fi
		fi


		if [ -f ${STRT}/Z_backup.${dirC}.err ]
		then
			cp -f ${STRT}/Z_backup.${dirC}.err ${PathMirror}${dirC}.rsync.loge

			rm -f ${TMP}
			diff ${STRT}/Z_backup.${dirC}.err ${PathMirror}${dirC}.rsync.loge >${TMP}
			if [ -s ${TMP} ] 
			then
				echo "\t Discrepency found between  ${STRT}/Z_backup.${dirC}.err  and  ${PathMirror}${dirC}.rsync.loge .\n"
			else
				rm -f ${STRT}/Z_backup.${dirC}.err
                		echo "\t Errlog file for ${dirC} saved:	${PathMirror}${dirC}.rsync.loge ..."
			fi
		fi


		if [ -d ${PathMirror}${dirC} ]
		then
			echo "\n\t Newly created backup image saved at:	${PathMirror}${dirC}/ ... "

		fi
	
		echo "\n `date` |rsync| End ${dirC} ..."

##############################################################################
##############################################################################
###
###	Section 3d:	Compare list of files
###

		echo "\t Building List of files on Master directory ..."

		( cd ${PathMaster}${dirC} ; find . -xdev -print ) | sort > ${STRT}/${dirC}.z1

		if [ -s ${STRT}/${dirC}.z1 ]
		then
			echo "\t\t Captured List of files on Master directory ..."
			cp -f ${STRT}/${dirC}.z1  ${PathMirror}${dirC}.rsync.src 
		else
			echo "\t\t Failed to capture List of files located in >> Master << directory ..."
		fi


		echo "\t Building List of files on Mirror directory ..."

		( cd ${PathMirror}${dirC} ; find . -xdev -print ) | sort >${STRT}/${dirC}.z2

		if [ -s ${STRT}/${dirC}.z2 ]
		then
			echo "\t\t Captured List of files on Mirror directory ..."
		else
			echo "\t\t Failed to capture List of files located in >> Mirror << directory ..."
		fi


		echo "\t Comparing lists of files on both disks ..."

		diff ${STRT}/${dirC}.z1 ${STRT}/${dirC}.z2 >${PathMirror}${dirC}.rsync.diff

		if [ -s ${PathMirror}${dirC}.rsync.diff ]
		then
			echo "\t\t Differences found between Master and Mirror directory ..."
			more ${PathMirror}${dirC}.rsync.diff
		else
			echo "\t\t List of files for SRC and TGT directories show no differences."
			echo "`date`| List of files for SRC and TGT directories show no differences." > ${PathMirror}${dirC}.rsync.diff
		fi


		echo "\n\t Creating stat report for files on Master directory ..."

		getSrcStatReport 	# ${PathMirror}${dirC}.rsync.stat.src 

		echo "\t\t 'stat' report for all saved:	${PathMirror}${dirC}.rsync.stat.src ."

		#rm -f ${STRT}/${dirC}.z1 ${STRT}/${dirC}.z2
	fi

	sync
	mv ${PathMirror}${dirC}.?* ${PathMirror}BK_LOGS
	echo "\t\t All reports for partition ${dirC} backup job have been moved into directory\n\t\t => '${PathMirror}BK_LOGS'."

	echo "\n `date` |logs| End ${dirC} ..."

	if [ ${TRKCHG} = "n" ]
	then
		echo "\n\t Discard previous backup set,  '${PathMirror}${dirC}-B2' ?\n\t\t [y/N] => \c"
		read zz
		if [ "${zz}" = "" ]
		then	zz="n"
		fi

		case ${zz} in
			y* | Y* )
				rm -rf ${PathMirror}${dirC}-B2/
				echo "\n\t\t PURGED:  '${PathMirror}${dirC}-B2'"
				;;
			* )	echo "\n\t\t *KEPT*:  '${PathMirror}${dirC}-B2'"
				;;
		esac
	fi
	echo "\n `date` |backup job| End ${dirC} ..."

    done
    echo "\n `date` |End PROGRAM `basename $0 '.sh' `"
fi

echo "\n===========   Job END   ============\n"

exit 0
exit 0
exit 0
