#!/bin/sh

###	$Id: $
###	Script to review 'history' report and extract 20 useful commands from recent history, elimating duplicates.

BASE=`basename "$0" ".sh" `
TMP=/tmp/${BASE}.tmp
rm -f ${TMP}

#HISTFILE=/home/ericthered/.bash_history
HISTFILE=./commandHist

find . -xdev -ctime +0 -name 'commandHist' -exec rm -f {} \;

if [ ! -s ${HISTFILE} ]
then
	echo "\n\t Script requires file '${HISTFILE}' as input.  Run 'history >./commandHist' at command prompt.\n\t Option "--debug" can be used to provide more detail on decision points.\n Bye!\n" ; exit 1
fi

DBG=0
VERB=0
while [ $# -gt 0 ]
do
	case $1 in
		--debug )	DBG=1  ; shift ;;
		--verbose )	VERB=1 ; shift ;;
		* )	echo "\n\t Invalid parameter '$1'.  Abandonning.\n Bye!\n" ; exit 1
	esac
done

TRICKLED=${TMP}.1
WORKFILE=${TMP}.2
TRACKER=${TMP}.track
#history | cut -c8- | grep -v '^ls' | grep -v '^rm' | grep -v '^cd' | grep -v '^sync' | grep -v '^more'

#cat ${HISTFILE} | grep -v '^ls' | grep -v '^rm' | grep -v '^cd' | grep -v '^sync' | grep -v '^more' 

tac ${HISTFILE} | cut -c8- | awk '{ if( NF >1 ){ if( $1 != "man" && $1 != "history" ){ print $0 ; } ; }; }' >${TRICKLED}
cp  ${TRICKLED} ${WORKFILE}
rm -f ${TRACKER}
touch ${TRACKER}

index=`wc -l ${TRICKLED} | awk '{ print $1 }' `
orig=${index}
while true
do
	if [ -s ${TRICKLED} ]
	then
		read line <${TRICKLED}
		tail --lines=+2 ${TRICKLED} >${WORKFILE}

		testor=`grep "${line}" ${TRACKER} 2>>/dev/null `
		if [ -z "${testor}" ]
		then
			if [ ${VERB} -eq 1 ] ; then  echo "\t ${line}" >&2 ; fi

			if [ ${DBG} -eq 1 ] ; then  echo "\t line[KEPT]= '${line}'" >&2 ; fi

			echo "${line}" >>${TRACKER}
			rm -f ${TMP}
			tester=`echo "${line}" | sed 's+^\./++' `
			if [ "${tester}" = "${line}" ]
			then
				awk -v comp="${line}" '{ if ( index( $0, comp ) == 0 ){ print $0 ; }; }' <${WORKFILE} >${TRICKLED}
			else
				if [ ${DBG} -eq 1 ] ; then  echo "\t './' prefix ..." >&2 ; fi
				awk -v comp="${line}" -v comp2="${tester}" '{ if ( ( index( $0, comp ) == 0 ) && ( index( $0, comp2 ) == 0 ) ) { print $0 ; }; }' <${WORKFILE} >${TRICKLED}
			fi
		else
			if [ ${DBG} -eq 1 ] ; then  echo "\t line[DUMP]= '${line}'" >&2 ; fi
			mv ${WORKFILE} ${TRICKLED}
		fi
	else
		break
	fi

	if [ ${DBG} -eq 1 ] ; then  echo "\t ${index}" >&2 ; fi
	index=`wc -l ${TRICKLED} | awk '{ print $1 }' `

	if [ ${index} -eq 0 ] ; then  break ; fi	
done

echo "\n All unique instances of commands from 'bash history' have been captured and saved.\n"

rm -f            ${BASE}.uniqueHist
tac ${TRACKER} > ${BASE}.uniqueHist
count=`wc -l ${BASE}.uniqueHist | awk '{ print $1 }' `

rm -f ${WORKFILE}
rm -f ${TRICKLED}
rm -f ${TRACKER}

echo "\n\n Last 20 commands used, most recent at top [Total: ${count}/${orig}]:\n\t File: ${BASE}.uniqueHist\n"
tac ${BASE}.uniqueHist | head -20 | awk '{ printf("\t %s\n", $0 ) }' | more

exit 0
exit 0
exit 0
