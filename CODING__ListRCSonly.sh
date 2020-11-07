#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: CODING__ListRCSonly.sh,v 1.4 2020/09/26 20:22:21 root Exp $
###
###	Script to identify files which only exist in RCS, and not extracted to directory in code PATH.
###
####################################################################################################

TMP=/tmp/`basename "$0" ".sh" `.tmp
Oasis=${Oasis:=/Oasis}

noMatch=""
showDetails=1
if [ "$1" = "--names" ] ; then  showDetails=0 ; fi

#cd ${Oasis}/bin
here=`pwd`

for ftypes in ods odt txt sh
do
	cd ${here}

	rm -f ${TMP}.todo
	( cd RCS ; ls *.${ftypes},v ) >${TMP}.todo 2>>/dev/null
	#cat ${TMP}.todo >&2

	if [ -s ${TMP}.todo ]
	then
		if [ ${showDetails} -eq 1 ] ; then  echo "\n####################################################################################\n Examining *.${ftypes} not retrieved from RCS ...\n" >&2 ; fi

		rm -f ${TMP}.nomatch

		for file in `cat ${TMP}.todo `
		do
			#date	2018.07.29.02.55.10;	author root;	state Exp;
			dateLin=`grep '^date' RCS/${file} | head -1 `
			date=`echo "${dateLin}" | awk '{ print $2 }' | cut -f1 -d\; `
			auth=`echo "${dateLin}" | awk '{ print $4 }' | cut -f1 -d\; `
			stat=`echo "${dateLin}" | awk '{ print $6 }' | cut -f1 -d\; `

			#grep '^#' RCS/${file} | grep '\$I' | grep 'd: ' | head -1 >&2
			dat=`grep '^#' RCS/${file} | grep '\$I' | grep 'd: ' | head -1 | 
				awk -v matchS="Id: \$" -v fName="${file}" -v vdate="${date}" -v vauth="${auth}" -v vstat="${stat}" '{ n=index($0,matchS) ; if( n == 0 ){
					print $0 ;
				}else{
					printf("\t     %s  [First Check-in] %s  %s  %s\n", fName, vdate, vauth, vstat ) ;
				} ;
			}' `
			base=`basename "${file}" ",v" `
			target="${here}/${base}"

			if [ ! -s ${target} ]
			then
				rm -f ${target}
				if [ ${showDetails} -eq 1 ]
				then
					echo "${dat}" | awk -v desc="NO_exec" '{ printf("  [%s,RCS]   %s\n", desc, $0 ) ; }' >>${TMP}.nomatch
				else
					echo "${base}" >>${TMP}.nomatch
				fi
			fi
		done	#file

		if [ -s ${TMP}.nomatch ] ; then  cat ${TMP}.nomatch ; if [ ${showDetails} -eq 1 ] ; then  echo "" ; fi ; fi
	else
		if [ ${showDetails} -eq 1 ] ; then  echo "\n No files matching '*.${ftypes}' pattern in current directory.\n" >&2 ; fi
	fi	# ${TMP}.todo
done	#ftype



#============================================================
#============================================================
#============================================================


rm -f ${TMP}.all
( cd RCS ; ls *,v ) >${TMP}.all 2>>/dev/null

rm -f ${TMP}.todo
cd ${here}

while read file
do
	if [ ! -d "${file}" ]
	then echo "${file}"
	fi
done <${TMP}.all | grep -v '.ods,v$' | grep -v '.odt,v$' | grep -v '.txt,v$' | grep -v '.sh,v$' | awk '{ if ( NF >0 ){ print $0 } ; }' >${TMP}.todo

if [ -s ${TMP}.todo ]
then
	if [ ${showDetails} -eq 1 ] ; then  echo "\n####################################################################################\n Examining other file types not retrieved from RCS ...\n" >&2 ; fi

	rm -f ${TMP}.nomatch

	for file in `cat ${TMP}.todo `
	do
		dateLin=`grep '^date' RCS/${file} | head -1 `
		date=`echo "${dateLin}" | awk '{ print $2 }' | cut -f1 -d\; `
		auth=`echo "${dateLin}" | awk '{ print $4 }' | cut -f1 -d\; `
		stat=`echo "${dateLin}" | awk '{ print $6 }' | cut -f1 -d\; `

		dat=`grep '^#' RCS/${file} | grep '\$I' | grep 'd: ' | head -1 | 
			awk -v matchS="Id: \$" -v fName="${file}" -v vdate="${date}" -v vauth="${auth}" -v vstat="${stat}" '{ n=index($0,matchS) ; if( n == 0 ){
				print $0 ;
			}else{
				printf("\t     %s  [First Check-in] %s  %s  %s\n", fName, vdate, vauth, vstat ) ;
			} ;
		}' `
		base=`basename "${file}" ",v" `
		target="${here}/${base}"

		if [ ! -s ${target} ]
		then
			rm -f ${target}
			if [ ${showDetails} -eq 1 ]
			then
				echo "${dat}" | awk -v desc="NO_exec" '{ printf("  [%s,RCS]   %s\n", desc, $0 ) ; }' >>${TMP}.nomatch
			else
				echo "${base}" >>${TMP}.nomatch
			fi
		fi
	done	#file

	if [ -s ${TMP}.nomatch ] ; then  cat ${TMP}.nomatch ; if [ ${showDetails} -eq 1 ] ; then  echo "" ; fi ; fi
else
	if [ ${showDetails} -eq 1 ] ; then  echo "\n No files of other than above types found in RCS.\n" >&2 ; fi
fi	# ${TMP}.todo
