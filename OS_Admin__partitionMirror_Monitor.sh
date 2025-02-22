#!/bin/sh

##########################################################################################################
###	$Id: OS_Admin__partitionMirror_Monitor.sh,v 1.3 2022/08/05 03:46:55 root Exp root $
###
###	This script is intended to perform an ongoing scan to report when an active RSYNC backup process terminates.
##########################################################################################################

test_STEP1()
{
echo "root        7520    7514 12 20:50 pts/0    00:05:46 rsync --checksum --one-file-system --recursive --outbuf=Line --links --perms --times --group --owner --devices --specials --verbose --out-format=%t|%i|%M|%b|%f| --delete-delay --whole-file --human-readable --protect-args --ignore-errors --msgs2stderr ./ /DB001_F7/
root        7514    7512  0 20:50 pts/0    00:00:25 rsync --checksum --one-file-system --recursive --outbuf=Line --links --perms --times --group --owner --devices --specials --verbose --out-format=%t|%i|%M|%b|%f| --delete-delay --whole-file --human-readable --protect-args --ignore-errors --msgs2stderr ./ /DB001_F7/
root        7512       1 17 20:50 pts/0    00:08:27 rsync --checksum --one-file-system --recursive --outbuf=Line --links --perms --times --group --owner --devices --specials --verbose --out-format=%t|%i|%M|%b|%f| --delete-delay --whole-file --human-readable --protect-args --ignore-errors --msgs2stderr ./ /DB001_F7/" >${TMP}
awk '{ printf("\trsync|%s\n", $0 ) ; }' ${TMP}
echo ""
}

test_STEP2()
{
echo "7520
7514
7512" >${TMP}.pid
awk '{ printf("\t pid |%s\n", $0 ) ; }' ${TMP}.pid
echo ""
}

test_STEP3()
{
echo "7514|7520
7512|7514
1|7512" >${TMP}.ppid
awk '{ printf("\tppid |%s\n", $0 ) ; }' ${TMP}.ppid
echo ""
}



. $Oasis/bin/INCLUDES__TerminalEscape_SGR.bh

BASE=`basename "$0" ".sh" `
TMP="/tmp/tmp.${BASE}.$$"

date | awk '{ printf("\n\t %s\n\n", $0 ) ; }'

if [ "$1" = "--snapshots" ]
then
	SNAP=1
else
	SNAP=0
fi

rm -f ${TMP}
ps -ef 2>&1 | grep -v grep | grep rsync | sort -r >${TMP}
#test_STEP1


if [ ! -s ${TMP} ]
then
	echo "\t RSYNC process is ${redON}not${redOFF} running (or has already ${greenON}terminated${greenOFF}).\n"
	exit 0
fi

awk '{ print $2 }' <${TMP} >${TMP}.pid
#test_STEP2


awk '{ printf("%s|%s\n", $3, $2) }' <${TMP} >${TMP}.ppid
#test_STEP3


for pid in `cut -f1 -d\| ${TMP}.ppid `
do
	PPID=`grep ${pid} ${TMP}.pid `
	PID=`grep '^'${pid} ${TMP}.ppid | cut -f2 -d\| `
	PRNT=`grep '^'${pid} ${TMP}.ppid | cut -f1 -d\| `
	if [ \( -n "${PPID}" \)  -a  \( "${PRNT}" -ne 1 \) ]
	then
		descr="child"
		echo "\t PID ${PID} is RSYNC ${cyanON}${italicON}${descr}${italicOFF}${cyanOFF} process ..."
	else
		descr="MASTER"
		echo "\t PID ${PID} is RSYNC ${yellowON}${descr}${yellowOFF} process ..."
	fi
done

getRsyncProcessStatus()
{
	testor=`ps -ef 2>&1 | awk -v THIS="${PID}" '{ if( $2 == THIS ){ print $0 } ; }' `
	MODE=`echo "${testor}" |
		awk '{ if( $NF ~ /^[/]DB001_F?[/]/ ){ print "2" }else{ print "1" } ; }' 2>>/dev/null ` 
}

getRsyncProcessStatus

if [ ${MODE} -eq 2 ]
then
	echo "\t RSYNC restore process under way ..."
	INTERVAL=60
	group5min=5
else
	echo "\t RSYNC backup process under way ..."
	INTERVAL=10
	group5min=30
fi

if [ -n "${testor}" ]
then
	echo "\n\t ${testor}\n" | sed 's+--+\n\t\t\t\t--+g' | awk '{
		rLOC=index($0,"rsync") ;
		if( rLOC != 0 ){
			sBeg=sprintf("%s", substr($0,1,rLOC-1) ) ;
			sEnd=sprintf("%s", substr($0,rLOC+5) ) ;
			sMid="\033[91;1mrsync\033[0m" ;
			printf("%s%s%s\n", sBeg, sMid, sEnd) ;
		}else{
			pLOC=index($0,"/DB001_") ;
			if( pLOC != 0 ){
				sBeg=sprintf("%s", substr($0,1,pLOC-1) ) ;
				sEnd=sprintf("%s", substr($0,pLOC) ) ;
				printf("%s\033[1m\033[93;1m%s\033[0m\n", sBeg, sEnd) ;
			}else{
				print $0 ;
			} ;
		} ;
	}'
	echo "\n\t Scanning at ${INTERVAL} second intervals ..."
	test ${SNAP} -eq 1 || echo "\t \c"
fi

durationCumulative=0
lapseCount=0
lapse=0

if [ ${SNAP} -eq 1 ]
then
	while true
	do
		getRsyncProcessStatus
		if [ -z "${testor}" ]
		then
			echo "\n\n\t RSYNC process (# ${PID}) has ${greenON}completed${greenOFF}.\n"
			date | awk '{ printf("\t %s\n\n", $0 ) ; }'
			exit 0
		fi
		jobLog=`ls -tr /site/Z_backup.*.err | tail -1 `
		echo "\t `tail -1 ${jobLog}`"
		sleep ${INTERVAL}
	done 2>&1 | uniq
else
	while true
	do
		getRsyncProcessStatus
		if [ -z "${testor}" ]
		then
			echo "\n\n\t RSYNC process (# ${PID}) has ${greenON}completed${greenOFF}.\n"
			date | awk '{ printf("\t %s\n\n", $0 ) ; }'
			exit 0
		fi
		echo ".\c"
		durationCumulative=`expr ${durationCumulative} + 1 `
		if [ ${durationCumulative} -eq ${group5min} ]
		then
			lapseCount=`expr ${lapseCount} + 1 `
			lapse=`expr ${lapseCount} \* 5 `
			echo "   ${lapse} min\n\t \c"
			durationCumulative=0
		fi
		sleep ${INTERVAL}
	done 
fi


exit 0
exit 0
exit 0

