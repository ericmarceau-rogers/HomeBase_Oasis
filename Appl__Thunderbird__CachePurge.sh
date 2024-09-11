#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: Appl__Thunderbird__CachePurge.sh,v 1.3 2024/05/23 00:24:01 root Exp $
###
###	Script to purge the cache files from all Thunderbird profiles.
###
####################################################################################################


###	.cache/thunderbird/OasisMega1.ThunderbirdProfile_DEFAULT/cache2/entries"

BASE=`basename "${0}" ".sh" `
TMP="/tmp/${BASE}.tmp"
rm -f ${TMP}

thisUser="${SUDO_USER}"
echo "${thisUser}" >&2

if [ ! -n "${thisUser}" ]
then
	echo "\t WARNING:  no value for 'SUDO_USER'.  Attempting to identify 'thisUser' by alternate means ..."
	thisUser=`grep -v nologin /etc/passwd | grep -v '/false' | grep -v '/sync' | grep -v '/root' | grep '/home' | head -1 | cut -f1 -d\: `
fi

if [ ! -n "${thisUser}" ] ; then  echo "\n\t Unable to identify User ID for ROOT user.\n Bye!\n" ; exit 1 ; fi

if [ "$1" = "--user" ]
then
	echo "thisUser= '${thisUser}'"
	shift
fi

LOGDIR=`dirname "$0" `
if [ "${LOGDIR}" = "." ]
then
        LOGDIR="${Oasis}/bin"
fi

TARGET=/home/${thisUser}

index=000

####################################################################################
####################################################################################
purgeDir()
{
	cd "${PURGEDIR}/" 
	if [ $? -eq 0 ]
	then
		echo "\n Getting purge list for "${PURGEDIR}/" ..."
		rm -f ${TMP}
		find . -mindepth 1 -maxdepth 1 \( ! -type d \) -print | sort -r | tail -n +6 >${TMP}
		if [ -s ${TMP} ]
		then
			count=`wc -l ${TMP} | awk '{ print $1 }' `
			if [ ${count} -gt 10 ]
			then
				head -5 ${TMP}
				echo "\t\t==="
				tail -5 ${TMP}
			else
				cat "${TMP}"
			fi

			echo "\t Proceed with mass delete of ${count} files listed in ${TMP} ? [y|N] => \c"
			read conf
			if [ -z "${conf}" ]
			then
				conf="N"
			fi
			case ${conf} in
				y* | Y* )
					dateStart=`date +%Y%m%d-%H%M%S `
					index=`expr ${index} + 1 | awk '{ printf("%03d", $0 ) }' `
					LOG="${LOGDIR}"/`basename $0 ".sh" `.${dateStart}.${index}.log
					echo "\t LOG = '${LOG}' ..."
					rm -fv $(ls -t "${LOGDIR}"/`basename $0 ".sh" `.*.log | tail -n+6 ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) ; }'
					cat ${TMP} | xargs rm -vf | tee "${LOG}"
					echo ""
					ls -l "${PURGEDIR}/"
					;;
				* )
					echo "\t\t Ignored as instructed ..."
					;;
			esac
		else
			echo "\n\t No purgeable files remaining ..."
		fi
	else
		echo "\n\t Unable to set '${PURGEDIR}/' as working directory."
	fi
} #purgeDir()


###
###	Phase I - Flush items under ${TARGET}/.cache/thunderbird
###
tCACHE=".cache/thunderbird"

for profile in `ls -d "${TARGET}/${tCACHE}"/* `
do
	PURGEDIR="${profile}/cache2/entries" 

	if [ -d "${PURGEDIR}/" ]
	then
		purgeDir
	else
		echo "\n\t Ignoring NON-directory '${PURGEDIR}'."
	fi
done


###
###	Phase II - Flush items under ${TARGET}/.cache/thunderbird
###
#tCACHE=".thunderbird/Crash Reports"

#for profile in `ls -d "${TARGET}/${tCACHE}"/* `
for profile in	"${TARGET}/.thunderbird/Crash Reports" \
		"${TARGET}/.thunderbird/OasisMega1.ThunderbirdProfile_DEFAULT/saved-telemetry-pings" \
		"${TARGET}/.thunderbird/OasisMega1.ThunderbirdProfile_DEFAULT/datareporting/archived/"*
do
	PURGEDIR="${profile}" 

	if [ -d "${PURGEDIR}/" ]
	then
		purgeDir
	else
		echo "\n\t Ignoring NON-directory '${PURGEDIR}'."
	fi
done



rm -f ${TMP}
echo "\n Done purging Thunderbird transient files.  Bye!\n"


exit 0
exit 0
exit 0
