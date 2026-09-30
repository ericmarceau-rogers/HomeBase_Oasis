#!/bin/sh

echo "\n Script for check and repair of offline USB backup drive ..."

doit=0
mode=1 ; mask="DB00[56]_F"

while [ $# -gt 0 ]
do
	case "${1}" in
		"--force" ) doit=1 ; shift ;;
		"--backup" ) mode=1 ; mask="DB00[56]_F" ; shift ;;
		"--system" ) mode=0 ; mask="DB001_F" ; shift ;;
		* ) echo "\n\t Option '${$1}' is invalid.  Valid options:  { --force } { --backup | --system }\n" ; exit 1 ;;
	esac
done

tmp=/tmp/$( basename "$0" ".sh" )_${mode}.tmp

#last=$( find ${tmp} \( ! -mtime 0 \) -print 2>>/dev/null )
last=$( find ${tmp} -newer "/var/log/boot.log.1" -print 2>>/dev/null )

if [ -n "${last}" ]
then
	echo "\n Program was already run today ..."
	ls -l ${last} | awk '{ printf("\t %s\n", $0 ) ; }'
	echo "\n NO action required.\n"
	rm -i ${last}
	exit 0
fi
echo "\n Proceeding ..."
rm -fv ${tmp} 2>>/dev/nul

if [ ${doit} -eq 1 ]
then
	#cd /dev/disk/by-label ; ls -l | eval grep \'${mask}\' | 
	cd /dev/disk/by-label
	case ${mode} in
		1 ) ls -l | eval grep \'${mask}\'
			;;
		0 ) ls -l | eval grep \'${mask}\' | tail -n +2
			;;
	esac | awk '{ 
			n=split( $0, val, "/" ) ;
			if( val[n] != "" ){
				printf("%s %s\n", $9, val[n] ) ;
			} ;
		}' >${tmp}

	if [ ! -s ${tmp} ]
	then
		echo "\n NOTE:  Selected drive is not attached to the computer.\n" ; exit 1
	fi

	#test -s ${tmp} && { cat ${tmp} | awk '{ printf("\t DEBUG 1 | %s\n", $0 ) ; }' ; }

	exist=$( ls /tmp/USB_fsck.* 2>>/dev/null | head -1 | awk '{ print $1 }' )
	#echo "\n\t DEBUG 2 | next = '${exist}' "

	if [ -z "${exist}" ]
	then
		while read label part
		do
			touch /tmp/USB_fsck.${label}
		done <${tmp}
	else
		#next=$( ls /tmp/USB_fsck.* 2>>/dev/null | head -1 )
		#echo "\n Continuing from last incomplete step ... ${next} ..."
		echo "\n Continuing from last incomplete step ... ${exist} ..."
	fi

	#ls -l /tmp/USB_fsck* | awk '{ printf("\t DEBUG 3 | %s\n", $0 ) ; }'

	while read label part
	do
		if [ -f /tmp/USB_fsck.${label} ]
		then
			device="/dev/${part}"

			testor=$( df | grep '^'${device} )
			#echo "${testor}" | awk '{ printf("\t DEBUG 4 (pre-umount)| %s\n", $0 ) ; }'

			RC=0
			if [ -n "${testor}" -a ${mode} -eq 0 ]
			then
				umount --verbose ${device} 2>&1
				#RC=$?
			fi | awk '{ printf("\n\t %s\n", $0 ) ; }'

			#echo "RC = $RC" | awk '{ printf("\t DEBUG 5 | %s\n", $0 ) ; }'
			testor=$( df | grep '^'${device} )
			echo "${testor}" | awk '{
				if( $0 == "" ){
					val="Drive is confirmed offline ..." ;
				}else{
					val=$0 ;
				} ;
				#printf("\t DEBUG 5 (post-umount)| %s\n", val ) ;
			}'

			if [ -z "${testor}" ]
			then
				#COM="fsck -V '${device}' -f"
				#COM="fsck -V '${device}' -f -p"
				COM="fsck -V '${device}' -f -y"
				echo "\n\t [${label}] COM:  ${COM}\n"
				eval ${COM}

				rm -fv /tmp/USB_fsck.${label} | awk '{ printf("\n\t %s\n", $0 ) ; }'
			else
				locn=$( df $0 | grep '^/dev' | awk '{ print $NF }' )
				#echo "\t DEBUG 6 | locn = ${locn}  vs  label = ${label}\n"
				if [ "${locn}" = "/${label}" ]
				then
					echo "\t SKIPPING '${device}' for fsck.  Script is resident on drive ..."
				else
					echo "\t SKIPPING '${device}' for fsck.  Failed 'umount' ..."
				fi
			fi
	
			echo "\n =========================================================\n"
		else
			echo "\n\t Recently performed 'fsck' on ${label}.  Skipping to next ..."
		fi
	done <${tmp}

	exist=$( ls /tmp/USB_fsck.* 2>>/dev/null | head -1 | awk '{ print $1 }' )
	#echo "\n\t DEBUG 2 | next = ${exist} "

	if [ -z "${exist}" ]
	then
		#flag only if task completed
		touch "/tmp/Devices__RepairPartition_Manual_${mode}.tmp"
	fi
else
	echo "\n\t To perform the action, you must retry using the '--force' option flag.\n" ; exit 1
fi
