#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: CODING__ConfirmVariableDefinitions.sh,v 1.4 2024/09/07 19:45:20 root Exp root $
###
###	This script will scan scripts to identify variables defined using the form ${*} and verify that value assignment statements exist.
###
####################################################################################################

scanVariables()
{
echo "Doing '${INPUT}' ..."
rm -f "${TMP}"
rm -f "${TMP}.fail"

grep -v '^#' "${INPUT}" |
awk -v vSTRT='${' -v vEND='}' -v vLTRL="='" '{
	remSTR=$0 ;
	Spos=index(remSTR, vSTRT ) ;
	#print Spos ;
	while ( Spos != 0 ){
		endSTR=substr(remSTR, Spos) ;
		Epos=index(endSTR, vEND ) ;
		#print Epos ;
		
		varSTR=substr(endSTR, 3, Epos-3 ) ;

		isLiteral=0 ;
		literal=index(endSTR,vLTRL) ;
		if ( literal != 0 && literal < Spos ){ 
			#printf("\t\tSpos= %s\n",Spos) | "cat 1>&2" ;
			#printf("\t\tvarSTR= %s\n",varSTR) | "cat 1>&2" ;
			#printf("\t\tliteral= %s\n",literal) | "cat 1>&2" ;
			isLiteral=1 ;
		} ;

		condAssign=index(varSTR,":=") ;
		if ( condAssign != 0 ){ 
			tmpSTR=substr(varSTR,1,condAssign-1) ;
			#printf("\t\ttmpSTR= %s\n",tmpSTR) | "cat 1>&2" ;

			tstring=sprintf("%s=${%s}",tmpSTR,varSTR) ;
			#printf("\t\ttstring= %s\n",tstring) | "cat 1>&2" ;

			testor=index($0,tstring)
			if ( testor == 0 ){
				printf("\tConditional assignments should be in the form '%s'.  Recommend change of '%s' assignment to fit that format.\n", tstring, tmpSTR ) | "cat 1>&2" ;
		       	} ;
		} ;


		if ( varSTR != "*" && varSTR ~ /[0-9]*/ && condAssign == 0 && isLiteral == 0 ){ print varSTR ; } ;

		remSTR=substr(endSTR, Epos+1 ) ;
		Spos=index(remSTR, vSTRT ) ;
	} ;
}' | sort | uniq | grep -v '^[0-9]*$' >"${TMP}"		### exclude references to positional parameters

if [ -s "${TMP}" ]
then
	if [ ${verbose} -eq 1 ]
	then
		echo "\nVariable identified in script:" >&2
		awk '{ printf("\t%s\n", $0 ) ; }' "${TMP}"
		echo "" >&2
	fi

	FAIL=0

	rm -f "${TMP}.fail"
	for var in `cat "${TMP}"`
	do
		testPass=0

		testor=`grep "${var}=" ${INPUT} | grep -v '^#'`
		if [ -n "${testor}" ]
		then
			testPass=1
		else
			testor=`grep "read ${var}" ${INPUT} | grep -v '^#'`
			if [ -n "${testor}" ]
			then
				testPass=1
			else
				testor=`grep "for ${var}" ${INPUT} | grep -v '^#'`
				if [ -n "${testor}" ]
				then
					testPass=1
				fi
			fi
		fi
	
		if [ ${testPass} -eq 0 ]
		then
			echo "\tMISSING value assignment to variable: '${var}'"
			FAIL=1
		fi
	done >"${TMP}.fail"

	if [ ${FAIL} -eq 1 ]
	then
		echo "\tVariable parsing FAILED for following cases:" >&2 ; cat "${TMP}.fail" >&2 ; exit 1
	else
		echo "\tVariable parsing PASSED!\n" >&2 ; exit 0
	fi
else
	echo "\tNo variables used in script." >&2 ; exit 0
fi
}



TMP=/tmp/$$.`basename "$0" ".sh" `.tmp

doAll=0
verbose=0

while [ $# -gt 0 ]
do
	case $1 in
		--verbose ) verbose=1 ; shift ;;
		--script )  INPUT="$2" ; shift ; shift ;;
		--all ) doAll=1 ; shift ;;
		* ) echo "\n\t Invalid parameter '$*' used on command line.  Only option available is '--verbose'.\n Bye!\n" ; exit 1 ;;
	esac
done

if [ ${doAll} -eq 0 ]
then
	test -n "${INPUT}" || { echo "\n\t ERROR:  Need name of script to be provided using '--script' option. \n Bye!\n" ; exit 1 ; }
	scanVariables
else
	rm -f "${TMP}.scripts}"
	ls | grep '\.sh$' >"${TMP}.scripts"
	ls -l "${TMP}.scripts}"

	test -s "${TMP}.scripts" || { echo "\n\t No *.sh script files in current directory.\n Bye!\n" ; exit 0 ; }

	while [ true ]
	do
		read INPUT
		test -n "${INPUT}" || { echo "\n\t Done!\n" ; exit 0 ; }

		echo "\n=============================================================================================="
		${0} --script "${INPUT}"
	done <"${TMP}.scripts"
fi


exit 0
exit 0
exit 0
