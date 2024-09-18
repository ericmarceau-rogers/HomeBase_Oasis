#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: UTIL__FixPrivileges.sh,v 1.1 2020/09/14 02:15:36 root Exp root $
###
###	Script to fix privileges to preset values depending on whether it is a directory or if a file, whether executable or not.
###
####################################################################################################

doFixPrivs()
{
	chown "${OwnerGroup}" "${item}"

	if [ -d "${item}" ]
	then
		chmod 775 "${item}"
	else
		if [ -x "${item}" ]
		then
			chmod 774 "${item}"
		else
			chmod 664 "${item}"
		fi
	fi
	ls -ld "${item}" | awk -v vItem="${item}" '{ printf("%9s %4s %12s %12s %12s %5s %2s %-5s  %s\n", $1, $2, $3, $4, $5, $6, $7, $8, vItem ) }'
}

doHandleItems()
{
	while read line
	do
		if [ ${doRecurse} -eq 1 ]
		then
			rm -f ${TMP}.list.depth
			find "${line}" -print | sort -r > ${TMP}.list.depth
			while read item
			do
				doFixPrivs
			done <${TMP}.list.depth
		else
			item="${line}"
			doFixPrivs
		fi
	done
	#done <${TMP}.list.top
}


############################################################################################
############################################################################################
###					MAIN PROGRAM
############################################################################################
############################################################################################


BASE=`basename "$0" ".sh" `
TMP="/tmp/${BASE}.tmp"

doAll=0
doRecurse=0
rawdat=`grep ':1000' /etc/passwd | cut -f1-3 -d":" `
primary=`echo "${rawdat}" | cut -f1 -d":" `
pgid=`echo "${rawdat}" | cut -f3 -d":" `
pgroup=`grep ":$pgid:" /etc/group | cut -f1 -d":" `
OwnerGroup="${primary}:${pgroup}"

echo ${OwnerGroup}

while [ $# -gt 0 ]
do
	case "${1}" in 
		--all )     doAll=1 ; shift ;;
		--recurse ) doRecurse="1" ; shift ;;
		--primary ) shift ;;
		--root )    OwnerGroup="root:root" ; shift ;;
		--shared )  OwnerGroup="root:${pgroup}" ; shift ;;
		* ) break ;;
	esac
done

if [ ${doAll} -eq 1 ]
then
	rm -f ${TMP}.list.top
	find . -mindepth 1 -maxdepth 1 -print	| 
		cut -c3-			|
		grep COMPARE			|
		sort -r				| doHandleItems
else
	for parm in "$@"
	do
		echo "${parm}"
	done					|
		sort -r				| doHandleItems
fi
