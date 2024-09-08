#!/bin/bash

###
###	Script to report all scripts in $Oasis/bin as in one of two groupings:  core  or  adhoc
###


pfmt()
{
	awk -v singlequote="'" '{
		n=split( $0, vals ) ; 
		if( n == 9 ){
			printf("%10s %2s %12s %12s %10d   %3s %2d %5s   %s\n", vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], vals[8], vals[9] ) ;
		}else{
			rem=vals[9] ;
			for( i=10 ; i<=n ; i++ ){
				rem=sprintf("%s %s", rem, vals[i] ) ;
			} ;
			printf("%10s %2s %12s %12s %10d   %3s %2d %5s   %s%s%s\n", vals[1], vals[2], vals[3], vals[4], vals[5], vals[6], vals[7], vals[8], singlequote, rem, singlequote ) ;
		} ;
	}'
}


doCore=0

while [ $# -gt 0 ]
do
	case "${1}" in
		"--core" ) doCore=1 ; shift ;;
		"--adhoc" ) doCore=2 ; shift ;;
		* ) printf "\n\t ERROR:  Invalid parameter included on command line.\n Bye!\n" ; exit 1 ;;
	esac
done

prefix_list="Appl CODING CONTINUITY CONVERT DATA Devices FIREWALL FW_Admin GUI HW_Admin IPTABLES KERN LOCAL NET OS_Admin PERF PostInstall Priority PROC PS RCS review SEC SW_Admin SW UTIL WEB"
#for prefix in Appl CODING CONTINUITY CONVERT DATA Devices FIREWALL FW_Admin GUI HW_Admin IPTABLES KERN LOCAL NET OS_Admin PERF PostInstall Priority PROC PS RCS review SEC SW_Admin SW UTIL WEB

tmp="/tmp/$(basename "${0}" ".sh" ).scripts"
core="$(basename "${0}" ".sh" ).scripts.core"
adhoc="$(basename "${0}" ".sh" ).scripts.adhoc"

ls | grep '.sh$' >"${tmp}"

if [ ${doCore} -eq 0 -o ${doCore} -eq 1 ]
then
	for prefix in ${prefix_list}
	do
		printf "\t Including %-16s references for list of 'core' scripts ...\n" "'${prefix}__'" >&2
		grep '^'"${prefix}__" "${tmp}"
	done >"${core}"
	echo ""

	countCore=$(wc -l "${core}" | awk '{ print $1 }' )

	printf "\n There are:\n\t %5d 'core'  scripts\n\n" ${countCore}
	ls -l "${core}"

	printf "\n Review list of 'core' scripts ? [ b(rief) | d(etailed) | N] => " ; read ans ; test -n ans || { ans="N" ; }
	case "${ans}" in
		b* | B* ) more  "${core}" ;;
		d* | D* ) xargs -a "${core}" -I '{}' ls -ld '{}' 2>>/dev/null | pfmt ;;
		* ) ;;
	esac
	if [ ${doCore} -eq 0 ]
	then
		printf "\n\t Hit return to continue ..." ; read ans
	fi
fi

if [ ${doCore} -eq 0 -o ${doCore} -eq 2 ]
then
	for prefix in ${prefix_list}
	do
		printf "\t Excluding %-16s references from list of 'adhoc' scripts ...\n" "'${prefix}__'" >&2
		grep -v '^'"${prefix}__" "${tmp}" >"${tmp}.rem"
		mv "${tmp}.rem" "${tmp}"
	done
	mv "${tmp}" "${adhoc}"

	countAdhoc=$(wc -l "${adhoc}" | awk '{ print $1 }' )

	printf "\n There are:\n\t %5d 'adhoc'  scripts\n\n" ${countAdhoc}
	ls -l "${adhoc}"

	printf "\n Review list of 'adhoc' scripts ? [ b(rief) | d(etailed) | N] => " ; read ans ; test -n ans || { ans="N" ; }
	case "${ans}" in
		b* | B* ) more  "${adhoc}" ;;
		d* | D* ) xargs -a "${adhoc}" -I '{}' ls -ld '{}' 2>>/dev/null | pfmt ;;
		* ) ;;
	esac
fi


