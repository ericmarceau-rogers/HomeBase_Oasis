#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: Appl__Firefox__CachePurge.sh,v 1.4 2024/09/11 17:56:15 root Exp $
###
###	Script to purge the cache files from all Firefox profiles.
###
####################################################################################################

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

if [ -z "${thisUser}" ] ; then  echo "\n\t Unable to identify User ID for ROOT user.\n Bye!\n" ; exit 1 ; fi
echo "\t thisUser = '${thisUser}' ..."

if [ "$1" = "--user" ]
then
	echo "thisUser= '${thisUser}'"
	shift
fi

TARGET=/home/${thisUser}

LOGDIR=`dirname "$0" `
if [ "${LOGDIR}" = "." ]
then
	LOGDIR="${Oasis}/bin"
fi


flushProfileCache()
{
	echo "\n Purging cache files for profile:   ${dir} ..."

	if [ -d "${pathProf2}/${dir}" ]
	then
		for locnPref in "cache2/doomed/" "cache2/entries/" "cache2/"
		do
			if [ -d ${pathProf2}/${dir}/${locnPref} ]
			then
				rm -f ${TMP}.duList
				ls "${pathProf}/${dir}/${locnPref}" >${TMP}.duList 2>>/dev/null
				if [ -s ${TMP}.duList ]
				then
					echo "\n\t From  \n\t   => ${pathProf2}/${dir}/${locnPref} ..."
					{	if [ ${verbose} -eq 1 ] ; then
							( cd ${pathProf2}/${dir}/${locnPref} && find .    \( ! -type d \) -exec ls -ld {} \; )
						else
							( cd ${pathProf2}/${dir}/${locnPref} && du -sh )
						fi
						( cd ${pathProf2}/${dir}/${locnPref} && find `ls` \( ! -type d \) -exec rm -f${verb} {} \; ) 
						echo "\t\t Purged all non-directory files ..."
					} 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
				else
					echo "\t NOTE:     No purgeable files in '${pathProf2}/${dir}/${locnPref}' ..."
				fi
			else
				echo "\t WARNING:  No directory at       '${pathProf2}/${dir}/${locnPref}' ..."
			fi
		done
	fi
}


purgeReportsAndSites()
{
	echo "\n Purging defunct datareports and site-related ..."

	echo "\t pathProf= '${pathProf}' ..."
	for locnPref in "OasisMega1.FirefoxProfile_DEFAULT/datareporting/archived/" "OasisMega1.FirefoxProfile_DEFAULT/storage/default/https+++www.tumblr.com/"
	do
		if [ -d "${pathProf}/${locnPref}" ]
		then
			rm -f ${TMP}.duList
			ls "${pathProf}/${locnPref}"* >${TMP}.duList 2>>/dev/null
			if [ -s ${TMP}.duList ]
			then
				#if [ ${locnPref} = "InstallTime" ]
				#then
				#	echo "\n\t From \n\t   => '${pathProf}/Crash Reports/' ..."
				#else
				#	echo "\n\t From \n\t   => '${pathProf}/Crash Reports/${locnPref}' ..."
				#fi

				{	if [ ${verbose} -eq 1 ] ; then  
					( cd ${pathProf} &&  { echo "\t Sub1 OK ..." ; ls -l        "${locnPref}"* ; } ) ; else  
					( cd ${pathProf} &&  { echo "\t Sub2 OK ..." ; du -sh       "${locnPref}"* ; } ) ; fi
					( cd ${pathProf} &&  { echo "\t Sub3 OK ..." ; rm -rf${verb} "${locnPref}"* ; } )
				} 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
			else
				echo "\t NOTE:     No purgeable files in '${pathProf}/${locnPref}' ..."
			fi
		fi
	done
}


purgeCrash()
{
	echo "\n Purging defunct crash reports ..."

	echo "\t pathProf= '${pathProf}' ..."
	for locnPref in "events/" "pending/" "submitted/" "InstallTime"
	do
		if [ -d "${pathProf}/Crash Reports/${locnPref}" ]
		then
			rm -f ${TMP}.duList
			ls "${pathProf}/Crash Reports/${locnPref}"* >${TMP}.duList 2>>/dev/null
			if [ -s ${TMP}.duList ]
			then
				if [ ${locnPref} = "InstallTime" ]
				then
					echo "\n\t From \n\t   => '${pathProf}/Crash Reports/' ..."
				else
					echo "\n\t From \n\t   => '${pathProf}/Crash Reports/${locnPref}' ..."
				fi

				{	if [ ${verbose} -eq 1 ] ; then  
					( cd ${pathProf} && { echo "\t Sub1 OK ..." ; ls -l        "Crash Reports/${locnPref}"* ; } ) ; else  
					( cd ${pathProf} && { echo "\t Sub2 OK ..." ; du -sh       "Crash Reports/${locnPref}"* ; } ) ; fi
					( cd ${pathProf} && { echo "\t Sub3 OK ..." ; rm -f${verb} "Crash Reports/${locnPref}"* ; } ) 
				} 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
			else
				echo "\t NOTE:     No purgeable files in '${pathProf}/Crash Reports/${locnPref}' ..."
			fi
		else
				echo "\t WARNING:  No directory at       '${pathProf}/Crash Reports/${locnPref}' ..."
		fi
	done
}


purgeDefunctProfiles()
{
	pathProf2="${TARGET}/.cache/mozilla/firefox"
	cd ${pathProf2} ; RC=$?

	if [ $RC -eq 0 ]
	then
		echo "\n Evaluating if profiles under '.cache/mozilla/firefox' are defunct ..."

		echo "\t pathProf2= '${pathProf2}' ..."
		
		for dir in *
		do
			if [ -d "${TARGET}/.mozilla/firefox/${dir}" ]
			then
				echo "\n\t Profile exists at '${TARGET}/.mozilla/firefox/${dir}'."
				echo "\t Keeping corresponding cache tree under \n\t   => ${pathProf2}/${dir} ..."
			else
				echo "\t Purging defunct cache tree \n\t   => ${pathProf2}/${dir} ..."
				{	if [ ${verbose} -eq 1 ] ; then  
						( cd ${pathProf2}/ && find ${dir} -exec ls -ld {} \; )
					else
						( cd ${pathProf2}/ && du -sh ${dir} )
					fi
					echo "\t\t Purging non-directory files ..."
					( cd ${pathProf2}/ && find ${dir} \( ! -type d \) -exec rm -f${verb}  {} \; )
					echo "\t\t Purging directories ..."
					( cd ${pathProf2}/ && find ${dir} \(   -type d \) -exec rm -f${verb}R {} \; )
				} 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
			fi
		done

		for dir in *
		do
			flushProfileCache
		done

		echo "\n Done purge for '${TARGET}' ..."
	fi
}


purgeAndLog()
{
	echo "\n =========================================================================================\n Doing assessment of => '${TARGET}' ..."

	purgeReportsAndSites

	purgeCrash

	purgeDefunctProfiles
}


dateStart=`date +%Y%m%d-%H%M%S `
echo "\t Looking in '${TARGET}' " >&2

###	FUTURES:  extract out common commands as reusable parameter.

verbose=0
if [ "$1" = "--verbose" ]
then
	verbose=1
	verb="v"
fi

##	The echo statement is structured to allow batch cleanup of multiple locations which would all contain a '.mozilla/firefox' directory.

echo "${TARGET}
" |
{
	index=000

	while read pathProf
	do
		dateStart=`date +%Y%m%d-%H%M%S `
		TARGET=`echo ${pathProf} | sed s+/\.mozilla/firefox++ | sed s+/\$++ `

		if [ "${pathProf}" != "${TARGET}/.mozilla/firefox" ]
		then
			pathProf="${TARGET}/.mozilla/firefox"
		fi

		if [ -d "${TARGET}/.mozilla/firefox" ]
		then
			index=`expr ${index} + 1 | awk '{ printf("%03d", $0 ) }' `
			LOG="${LOGDIR}"/`basename $0 ".sh" `.${dateStart}.${index}.log
			echo "\t LOG = '${LOG}' ..."
			rm -fv $(ls -t "${LOGDIR}"/`basename $0 ".sh" `.*.log | tail -n+3 ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) ; }'

			purgeAndLog | tee "${LOG}"
		fi
	done

	echo "\n Done purging Firefox transient files.  Bye!\n"
}

exit 0
exit 0
exit 0
