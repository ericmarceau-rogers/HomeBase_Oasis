#!/bin/sh

###	$Id: quickRSYNC.sh,v 1.1 2020/10/20 19:20:00 root Exp root $
###	Simplified version of 'rsync' backup without the additional post-backup tasks that are performed by 'OS_Admin__partitionSecondary_Mirror.sh'.

thisHost=`hostname`

case ${thisHost} in
	OasisMini | OasisMidi )
		PathMaster="/media/ericthered/"
		;;
	OasisMega1 )
		PathMaster="/"
		;;
	* )	echo "\n\t This script is NOT to be used from this host. \n Bye!\n" ; exit 1 ;;
esac

#showProgress="--info=progress1"	## Doing this option causes multiple lines per file mirrored.
STRT=`pwd`

for masterPart in 1 2 3 4 5 6 7
do
	dirC=DB001_F${masterPart}

	case ${masterPart} in
		1 )	mirrorPart=8 ;;
		2 )	mirrorPart=5 ;;
		5 )	mirrorPart=2 ;;
		* )	mirrorPart=${masterPart} ;;
	esac

	PathMirror="/media/ericthered/DB002_F${mirrorPart}/"
	STRT="${PathMirror}"
	SWIP="/media/ericthered/"

	MirrorBatch="${STRT}Z_backup.${dirC}.batch"

	echo "\n SOURCE= ${PathMaster}${dirC}"
	echo " MIRROR= ${PathMirror}${dirC} ...\n"

	echo "\t Proceed ? [y|N] => \c" ; read doit
	if [ -z "${doit}" ] ; then  doit="N" ; fi

	case ${doit} in
		y* | Y* )
			rm -f ${STRT}Z_backup.${dirC}.out ${STRT}Z_backup.${dirC}.err ${MirrorBatch}
			rm -f ${SWIP}Z_backup.${dirC}.out ${SWIP}Z_backup.${dirC}.err

			COM="rsync --one-file-system --recursive --links --perms --times --group --owner --devices --specials --verbose --out-format=\"%t|%i|%
M|%b|%f|\" --update --checksum --delete-during --whole-file --human-readable --protect-args --ignore-errors --msgs2stderr ${showProgress} ./ ${PathMirror}${di
rC}/ 2>${SWIP}Z_backup.${dirC}.err | tee ${SWIP}Z_backup.${dirC}.out"

			#echo "\n===================================================================================\n${COM}\n================================
==========================================\n"

                	echo "\n `date` |rsync| Start ${dirC} ..." >&2
                	cd ${PathMaster}${dirC}

                	echo "cd ${PathMaster}${dirC}
				${COM}
				mv ${SWIP}Z_backup.${dirC}.out ${STRT}Z_backup.${dirC}.out
				mv ${SWIP}Z_backup.${dirC}.err ${STRT}Z_backup.${dirC}.err
			" >${MirrorBatch}

			echo "\n===================================================================================\n`cat ${MirrorBatch}`\n===================
=======================================================\n"

			chmod 700 ${MirrorBatch}
			nohup nice -17 ${MirrorBatch} &

			echo "\n 'rsync' in progress in background.\n\n Log files:\n\t Z_backup.${dirC}.out\n\t Z_backup.${dirC}.err\n" >&2
			exit
 			;;
		* )	echo "\t\t '${dirC}' skipped ..." ;;
	esac
done


exit 0
exit 0
exit 0
