#!/bin/sh

###	$Id: reSetPriority.sh,v 1.2 2020/11/08 21:03:28 root Exp $
###
###	Script to reprioritize processes using language which is more intuitive to non-tech users.

abandonRenice()
{
	echo "\n\t To ensure stable system, no process may be re-prioritized to value lower than '-18'! \n\t Please specify new option value.\n Bye!\n" ; exit 1
}

usage()
{
	echo "\n\t Invalid parameter used on command line.  Only allowed:  [ --raise {difference} | --lower {difference} | --set {absolute} ]\n Bye!\n" ; exit 1 
}

pidList()
{
	echo "\n\t Must specify process ID list with '--pid' option.\n Bye!\n" ; exit 1
} 

BASE=`basename "$0" ".sh" `
TMP="/tmp/${BASE}.nice"

mode=2

while [ $# -gt 0 ]
do
	case $1 in
		--raise )	mode=1; doNice="-${2}" ; shift ; shift ;;
		--lower )	mode=1; doNice="${2}" ; shift ; shift ;;
		--set )		mode=2; doNice="${2}" ; shift ; shift ;;
		--pid )		PIDs="$*" ; shift $# ; break ;;
		* ) usage ;;
	esac
done

if [ -z "${PIDs}" ] ; then  pidList ; fi

echo "\n  NOTE:  All processes with nice value of '-20' (aka system processes, maximum 'not-nice' meaning highest priority) and\n         all spawns of 'kworker/' or 'ksoftirqd/' are ignored by this script ..."

#ps -eo "%p %r %P %n %c" >${TMP}
ps -eo pid,ni,comm | awk '{ if( $2 != "-20" && index($3,"kworker/") != 1  &&  index($3,"ksoftirqd/") != 1 ){ print $0 } ; }' >${TMP}

niceNOW=`for PID in \`echo ${PIDs} \`
do
	cat ${TMP} | awk -v thisProc="${PID}" '{ if( $1 == thisProc ){ print $2 }; }'
done | sort -nr | uniq | head -1 `

case ${mode} in
	1 )	niceNEW=`expr ${niceNOW} + ${doNice} ` ;;
	2)	niceNEW=${doNice} ;;
esac

###	This approach was not interpreted as expected:  'expr -18 > ${niceNEW} '
if [ "-18" -gt "${niceNEW}" ] ; then  abandonRenice ; fi

echo "\n  Process(es) set with 'nice' value of => ${niceNEW} \n"

eval renice -n ${niceNEW} ${PIDs} | awk '{ printf("\t %s\n", $0 ) ; }'
echo ""

eval ps -o pid,ppid,pgid,ni,args ${PIDs}
echo ""

exit 0
exit 0
exit 0
