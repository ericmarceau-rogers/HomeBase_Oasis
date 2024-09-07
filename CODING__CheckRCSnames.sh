#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: CODING__CheckRCSnames.sh,v 1.16 2024/09/07 16:44:41 root Exp root $
###
###	Script to identify existence of matching RCS file for scripts and flag those which don't have one. The script also lists all historic versions.
###
####################################################################################################

TMP=/tmp/`basename "$0" ".sh" `.tmp

divider="##########################################"
doCoder=0
doSort=0
noMatch=""
showAll=0
mods=0
verbose=0
names=0
norcs=0

while [ $# -gt 0 ]
do
	case $1 in
		--recent )	doSort=1  ; shift ;;
		--coder )	doSort=1  ; doCoder=1	; shift ;;
		--verbose )	verbose=1 ; shift ;;
		--history )	showAll=1 ; mods=0	; shift ;;
		--mods )	showAll=0 ; mods=1	; shift ;;
		--norcs )	norcs=1   ; shift ;;
		--names )	names=1   ; shift ;;
	esac
done

if [ ${names} -eq 0 -a -t 1 -a ${mods} -eq 0 ] ; then  echo "" ; fi

displayRcsDetails_A()
{
	#  [EDIT]         ###	$Id: CODING__CheckRCSnames.sh,v 1.16 2024/09/07 16:44:41 root Exp root $
	#echo "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+"
	#echo "${dat}" | awk -v desc="${desc}" '{ printf("  [%s]         %s\n", desc, $0 ) ; }'
	format="  [%s]          %-${max}s  %-4s  %s\n"
	head -1 ${TMP}.oneitem | 
	awk -v fmt="${format}" -v desc="${desc}" -v id=\$Id\: '{ 
		str=index( $0, id) ;
		rem=substr( $0, str) ;
		#print rem ;
		pos=index( rem,",v")+1 ;
		L=length(rem) ;
		s1=substr( rem, 1, pos) ; 
		s2=substr( rem, pos+2) ;
		#print pos ;
		#print s1 ;
		#print s2 ;
		#print L ;
		spc=index( s2, " ") ;
		ver=substr( s2, 1, spc-1) ;
		s3=substr( s2, spc+1) ;
		printf(fmt, desc, s1, ver, s3 ) ;
    				}'
	matchRCS=1
}


displayRcsDetails_B()
{
	#echo "${dat}" | awk -v desc="${desc}" '{ printf("        [%s]   %s\n", desc, $0 ) ; }'
	#echo "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+"

	format="         [%s]   %-${max}s  %-4s  %s\n"
	head -1 ${TMP}.oneitem | 
	awk -v fmt="${format}" -v desc="${desc}" -v id=\$Id\: '{ 
		str=index( $0, id) ;
		rem=substr( $0, str) ;
		#print rem ;
		pos=index( rem,",v")+1 ;
		L=length(rem) ;
		s1=substr( rem, 1, pos) ; 
		s2=substr( rem, pos+2) ;
		#print pos ;
		#print s1 ;
		#print s2 ;
		#print L ;
		spc=index( s2, " ") ;
		ver=substr( s2, 1, spc-1) ;
		s3=substr( s2, spc+1) ;
		printf(fmt, desc, s1, ver, s3 ) ;
	}'
	matchRCS=1
}


printDetailsNoName()
{
	testor3=`echo "${dat}" | awk '{ if ( index($0,"Id: \$") > 0 ) print $0 ; }' `

	desc="EDIT"
	if [ -z "${testor3}" ] ; then  
		if [ -n "${dat}" ]
		then
			desc="${desc},MALFORMED_HEADER"
		else
			desc="${desc},NO_RCShead"
		fi
	fi
	echo "${file}" |
		awk -v desc="${desc}" '{
			printf("  [%s,NO_RCS]   %s\n", desc, $0 ) ;
		}' >>${TMP}.nomatch
	noMatch="${noMatch} ${file}"
}


getFileRCSdetails()
{
	#dat=`grep 'Id: ' ${file} | grep '^#' `
	target="RCS/${file},v"

	rm -f ${TMP}.oneitem
	grep 'Id: ' ${file} | grep '^#' >${TMP}.oneitem
	read dat <${TMP}.oneitem

	if [ -s ${target} ]
	then
		if [ ${names} -eq 0 ]
		then
			if [ -t 1 -a ${showAll} -eq 1 ]
			then
				echo "\n\t >>> ${file} <<<"
			fi
		fi

		testor=`echo "${dat}" | awk '{ if ( index($0,"Exp \$") > 0 ) print $0 ; }' `
		if [ -n "${testor}" ] ; then  desc="exec" ; else  desc="EDIT" ; fi

		testor2=`echo "${dat}" | grep "${file}" `
		if [ -z "${testor2}" ] ; then  desc="${desc},MALFORMED_HEADER" ; fi

		if [ "${desc}" = "EDIT" ]
		then
			if [ ${norcs} -eq 0 ]
			then
				if [ ${names} -eq 1 ]
				then
					echo "${file}"
				else
					displayRcsDetails_A
				fi
			fi
		else
			if [ \( ${names} -eq 0 \) -a \( ${mods} -eq 0 \) -a \( ${norcs} -eq 0 \) ]
			then
				displayRcsDetails_B
			fi
		fi

		if [ \( ${names} -eq 0 \) -a \( ${norcs} -eq 0 \) ]
		then
			if [ ${showAll} -eq 1 ]
			then
				grep 'Id: ' ${target} | grep '^#' | awk '{ printf("   [RCS]   %s\n", $0 ) ; }'
			fi
		fi
	else
		if [ ${norcs} -eq 1 ]
		then
			if [ ${names} -eq 1 ]
			then
				echo "${file}" >>${TMP}.nomatch
			else
				printDetailsNoName
			fi
		else
			if [ ${names} -eq 0 ]
			then
				printDetailsNoName
			fi
		fi
	fi

}	#getFileRCSdetails()



group_2()
{
	if [ -s ${TMP}.report ]
	then
		#[exec]   $Id: CODING__CheckRCSnames.sh,v 1.16 2024/09/07 16:44:41 root Exp root $
		if [ ${doSort} -eq 1 ]
		then
			if [ ${doCoder} -eq 1 ]
			then
				sort --key=7,7 --key=5,5 --key=6,6 ${TMP}.report
			else
				sort --key=5,5 --key=6,6 ${TMP}.report
			fi
		else
			cat ${TMP}.report
		fi
	fi

	if [ ${norcs} -eq 1 ]
	then
		if [ -s ${TMP}.nomatch ]
		then  
			cat ${TMP}.nomatch
			if [ ${names} -eq 0 ] 
			then
				echo ""
			fi
		fi
	else
		if [ \( ${names} -eq 0 \) -a \( ${mods} -eq 0 \) ] 
		then
			if [ -s ${TMP}.nomatch ]
			then  
				if [ ${matchRCS} -eq 1 ]
				then
					echo ""
				fi
				cat ${TMP}.nomatch
				echo ""
			fi
		fi
	fi
}	#group_2()


group_1a()
{
	rm -f ${TMP}.nomatch

	max=0
	for file in `cat ${TMP}.todo `
	do
		len=`echo "${file}" | wc -c `
		if [ ${len} -gt ${max} ]
		then
			max=${len}
		fi
		#echo "${len}  ${file}"
	done	# | sort -nr
	max=`expr ${max} + 2 + 6 `

	matchRCS=0
	for file in `cat ${TMP}.todo `
	do
		getFileRCSdetails
	done	#file
}	#group_1a()


group_1b()
{
	rm -f ${TMP}.nomatch

	max=0
	for file in `cat ${TMP}.todo `
	do
		len=`echo "${file}" | wc -c `
		if [ ${len} -gt ${max} ]
		then
			max=${len}
		fi
		#echo "${len}  ${file}"
	done	# | sort -nr
	max=`expr ${max} + 2 + 6 `

	for file in `cat ${TMP}.todo `
	do
		matchRCS=0
		getFileRCSdetails
	done	#file
}	#group_1b()


fileTypeActions()
{
	rm -f ${TMP}.todo

	ls *.${ftypes} >${TMP}.todo 2>>/dev/null

	if [ -s ${TMP}.todo ]
	then
		if [ \( ${names} -eq 0 \) -a \( ${mods} -eq 0 \) ]
		then
			echo "\n${divider}${divider}"
			echo   " Examining *.${ftypes} ...\n"
		fi

		rm -f ${TMP}.report
		group_1a >${TMP}.report

		group_2
	else
		if [ \( ${names} -eq 0 \) -a \( ${verbose} -eq 1 \) ] 
		then
			echo "\n No files matching '*.${ftypes}' pattern in current directory.\n"
		fi
	fi	#-s ${TMP}.todo

}	#fileTypeActions()


for ftypes in ods odt txt sh
do
	fileTypeActions
done	#ftype

rm -f ${TMP}.all
ls >${TMP}.all

rm -f ${TMP}.todo

while read file
do
	if [ ! -d "${file}" ]
	then echo "${file}"
	fi
done <${TMP}.all | grep -v '.ods$' | grep -v '.odt$' | grep -v '.txt$' | grep -v '.sh$' |
	awk '{ if ( NF >0 ){ print $0 } ; }' >${TMP}.todo

if [ -s ${TMP}.todo ]
then
	if [ ${norcs} -eq 1 ]
	then
		if [ \( ${names} -eq 0 \) -a \( ${mods} -eq 0 \) ]
		then
			echo "\n${divider}${divider}"
			echo   " Examining other files of remaining types ...\n"
		fi
		rm -f ${TMP}.report
		group_1b >${TMP}.report

		group_2
	else
		if [ ${names} -eq 0 ]
		then
			if [ ${mods} -eq 0 ]
			then
				echo "\n${divider}${divider}"
				echo   " Examining other files of remaining types ...\n"
			fi
			rm -f ${TMP}.report
			group_1b >${TMP}.report

			group_2
		fi
	fi
fi	#-s ${TMP}.todo


exit 0
exit 0
exit 0
