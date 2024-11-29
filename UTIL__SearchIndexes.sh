#!/bin/bash

###
###	Script to either give regex pattern for a specified search string and 
###	perform search for matching items in pre-built indexes of files or 
###	directories for all partitions on the system's boot disk.
###
###	CURRENT -- Option --single keeps space between pattern words for scanning.
###
###	FUTURES -- Option to make a single string with no spaces between pattern words
###

index=${index:-/DB001_F2/LO_Index}

###	See also:	UTIL__MapStringToGeneralizedSearch.sh

usage()
{
	printf "\n\t usage: $(basename "$0") [ --single ] [ --notype ] [-={ftype} ] [ --pattern ] {string} \n\n" ; exit 1
}

if [ $# -eq 0 ]
then
	usage
fi

doFiles=1
doSingle=0
ftype=pdf
patternOnly=0
reportQuotes=0
reportBracketR=0
reportBracketS=0
reportBraces=0

while [ $# -gt 0 ]
do
	case $1 in
		--fils ) doFiles=1 ; shift ;;
		--dirs ) doFiles=0 ; ftype="" ; shift ;;
		--basic ) doSingle=1 ; ftype="" ; shift ;;
		--single ) doSingle=1 ; shift ;;
		--notype ) ftype="" ; shift ;;
		--pattern ) patternOnly=1 ; shift ; break ;;
		--quotes ) reportQuotes=1 ; shift ;;
		--bracketR ) reportBracketR=1 ; shift ;;
		--bracketS ) reportBracketS=1 ; shift ;;
		--braces ) reportBraces=1 ; shift ;;
		-=* )	ftype=$(echo "$1" | cut -c3- ) ; shift ;;
		--* ) printf "\n\t Invalid option specified.\n" ; usage ; exit 1 ;;
		* )	break ;;
	esac
done
#printf "${ftype}\n"

cd ${index}

if [ ${doFiles} -eq 1 ]
then
	INDEX="INDEX.allDrives.f.txt"
else
	INDEX="INDEX.allDrives.d.txt"
fi


method3()
{
	###	$@ at this level is limited to scope of function, i.e. variables passed at function call.
	for pattern in $@
	do
		echo "${pattern}" | sed 's/[[:alpha:]]/[\u&\l&]/g'
	done
}

###	$@ at this level is visible only to top-level code, not code wrapped in functions.
### Output - Method 3
#[Aa][Bb]*[Cc]1
#[Dd]2[Ee]?[Ff]
			

matchBaseName(){
	###
	###	This code segment doesn't work if only one pattern in pattern list ${pSingle}
	###
	awk -v mode=${doSingle} -v allPats="${pSingle}" '{
		n=split( $0, filename, "/" ) ;
		if( mode == 1 ){
			if( filename[n] ~ allPats ){
				print $0 ;
			} ;
		}else{
			strN=split( allPats, pats ) ;
			doPrint=0 ;

			for( i=1 ; i <= strN ; i++ ){
				if( filename[n] ~ pats[i] ){
					doPrint=1 ;
				}else{
					break ;
				} ;
			} ;

			if( doPrint == 1 ){
				print $0 ;
			} ;
		} ;
	}' <"${tmp}" >"${basn}"
	mv "${basn}" "${tmp}"
}



genCharReports(){
	if [ ${reportQuotes} -eq 1 ]
	then
		quotes="${base}.quotes"		; rm -f "${quotes}"

		awk -v pat="'" 'index( $0, pat ) { print $0 ; }' <"${tmp}" >"${quotes}" ;

		test -s "${quotes}" && { wc -l "${quotes}" | awk '{ printf("\t %6d  %s\n", $1, $2 ) ; }' ; } || { rm -f "${quotes}" ; }
	fi

	if [ ${reportBracketR} -eq 1 ]
	then
		bracketR="${base}.bracketR"	; rm -f "${bracketR}"

		awk -v pat1='(' -v pat2=')' '( index( $0, pat1 ) || index( $0, pat2 ) ) { print $0 ; }' <"${tmp}" >"${bracketR}" ;

		test -s "${bracketR}" && { wc -l "${bracketR}" | awk '{ printf("\t %6d  %s\n", $1, $2 ) ; }' ; } || { rm -f "${bracketR}" ; }
	fi 

	if [ ${reportBracketS} -eq 1 ]
	then
		bracketS="${base}.bracketS"	; rm -f "${bracketS}"

		awk -v pat1='[' -v pat2=']' '( index( $0, pat1 ) || index( $0, pat2 ) ) { print $0 ; }' <"${tmp}" >"${bracketS}" ;

		test -s "${bracketS}" && { wc -l "${bracketS}" | awk '{ printf("\t %6d  %s\n", $1, $2 ) ; }' ; } || { rm -f "${bracketS}" ; }
	fi

	if [ ${reportBraces} -eq 1 ]
	then
		braces="${base}.braces"		; rm -f "${braces}"

		awk -v pat1='{' -v pat2='}' '( index( $0, pat1 ) || index( $0, pat2 ) ) { print $0 ; }' <"${tmp}" >"${braces}" ;

		test -s "${braces}" && { wc -l "${braces}" | awk '{ printf("\t %6d  %s\n", $1, $2 ) ; }' ; } || { rm -f "${braces}" ; }
	fi 
}


if [ ${patternOnly} -eq 1 ]
then
	for strs in $@
	do
		method3 ${strs}
	done | awk 'BEGIN{ printf("\n") ; }{ printf("\t %s\n", $0 ) ; }END{ printf("\n") ; }'
	exit
else
	patterns=()
	patterns[0]=""

	i=0
	for strs in $@
	do
		i=$((i+=1))
		patterns[${i}]=$(method3 ${strs} )
	done
fi

pCount=$#

base=$(basename "${0}" ".sh" )

tmp="${base}.tmp"		; rm -f "${tmp}"
items="${base}.items"		; rm -f "${items}"
xcpt="${base}.exceptions"	; rm -f "${xcpt}"
basn="${base}.basename"		; rm -f "${basn}"

case ${pCount} in
	1 )
		{
			printf "\n\t ${patterns[1]}\n\n"
		} >&2

		grep "${patterns[1]}" INDEX.allDrives.f.txt > ${tmp}
		;;
	2 )
		{
			printf "\n\t ${patterns[1]}\n"
			printf "\t ${patterns[2]}\n\n"
		} >&2

		pSingle="${patterns[1]} ${patterns[2]}"

		if [ ${doSingle} -eq 1 ]
		then
			#grep "${patterns[1]} ${patterns[2]}" INDEX.allDrives.f.txt
			grep "${pSingle}" INDEX.allDrives.f.txt
		else
			grep "${patterns[1]}" INDEX.allDrives.f.txt	|
			grep "${patterns[2]}"
		fi >"${tmp}"
		;;
	3 )
		{
			printf "\n\t ${patterns[1]}\n"
			printf "\t ${patterns[2]}\n"
			printf "\t ${patterns[3]}\n\n"
		} >&2

		pSingle="${patterns[1]} ${patterns[2]} ${patterns[3]}"

		if [ ${doSingle} -eq 1 ]
		then
			#grep "${patterns[1]} ${patterns[2]} ${patterns[3]}" INDEX.allDrives.f.txt
			grep "${pSingle}" INDEX.allDrives.f.txt
		else
			grep "${patterns[1]}" INDEX.allDrives.f.txt	|
			grep "${patterns[2]}"				|
			grep "${patterns[3]}"
		fi >"${tmp}"
		;;
	4 )
		{
			printf "\n\t ${patterns[1]}\n"
			printf "\t ${patterns[2]}\n"
			printf "\t ${patterns[3]}\n"
			printf "\t ${patterns[4]}\n\n"
		} >&2

		pSingle="${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]}"

		if [ ${doSingle} -eq 1 ]
		then
			#grep "${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]}" INDEX.allDrives.f.txt
			grep "${pSingle}" INDEX.allDrives.f.txt
		else
			grep "${patterns[1]}" INDEX.allDrives.f.txt	|
			grep "${patterns[2]}"				|
			grep "${patterns[3]}"				|
			grep "${patterns[4]}"
		fi >"${tmp}"
		;;
	5 )
		{
			printf "\n\t ${patterns[1]}\n"
			printf "\t ${patterns[2]}\n"
			printf "\t ${patterns[3]}\n"
			printf "\t ${patterns[4]}\n"
			printf "\t ${patterns[5]}\n\n"
		} >&2

		pSingle="${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]}"

		if [ ${doSingle} -eq 1 ]
		then
			#grep "${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]}" INDEX.allDrives.f.txt
			grep "${pSingle}" INDEX.allDrives.f.txt
		else
			grep "${patterns[1]}" INDEX.allDrives.f.txt	|
			grep "${patterns[2]}"				|
			grep "${patterns[3]}"				|
			grep "${patterns[4]}"				|
			grep "${patterns[5]}"
		fi >"${tmp}"
		;;
	6 )
		{
			printf "\n\t ${patterns[1]}\n"
			printf "\t ${patterns[2]}\n"
			printf "\t ${patterns[3]}\n"
			printf "\t ${patterns[4]}\n"
			printf "\t ${patterns[5]}\n"
			printf "\t ${patterns[6]}\n\n"
		} >&2

		pSingle="${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]} ${patterns[6]}"

		if [ ${doSingle} -eq 1 ]
		then
			#grep "${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]} ${patterns[6]}" INDEX.allDrives.f.txt
			grep "${pSingle}" INDEX.allDrives.f.txt
		else
			grep "${patterns[1]}" INDEX.allDrives.f.txt	|
			grep "${patterns[2]}"				|
			grep "${patterns[3]}"				|
			grep "${patterns[4]}"				|
			grep "${patterns[5]}"				|
			grep "${patterns[6]}"
		fi >"${tmp}"
		;;
	7 )
		{
			printf "\n\t ${patterns[1]}\n"
			printf "\t ${patterns[2]}\n"
			printf "\t ${patterns[3]}\n"
			printf "\t ${patterns[4]}\n"
			printf "\t ${patterns[5]}\n"
			printf "\t ${patterns[6]}\n"
			printf "\t ${patterns[7]}\n\n"
		} >&2

		pSingle="${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]} ${patterns[6]} ${patterns[7]}"

		if [ ${doSingle} -eq 1 ]
		then
			#grep "${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]} ${patterns[6]} ${patterns[7]}" INDEX.allDrives.f.txt
			grep "${pSingle}" INDEX.allDrives.f.txt
		else
			grep "${patterns[1]}" INDEX.allDrives.f.txt	|
			grep "${patterns[2]}"				|
			grep "${patterns[3]}"				|
			grep "${patterns[4]}"				|
			grep "${patterns[5]}"				|
			grep "${patterns[6]}"				|
			grep "${patterns[7]}"
		fi >"${tmp}"
		;;
	8 )
		{
			printf "\n\t ${patterns[1]}\n"
			printf "\t ${patterns[2]}\n"
			printf "\t ${patterns[3]}\n"
			printf "\t ${patterns[4]}\n"
			printf "\t ${patterns[5]}\n"
			printf "\t ${patterns[6]}\n"
			printf "\t ${patterns[7]}\n"
			printf "\t ${patterns[8]}\n\n"
		} >&2

		pSingle="${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]} ${patterns[6]} ${patterns[7]} ${patterns[8]}"

		if [ ${doSingle} -eq 1 ]
		then
			#grep "${patterns[1]} ${patterns[2]} ${patterns[3]} ${patterns[4]} ${patterns[5]} ${patterns[6]} ${patterns[7]} ${patterns[8]}" INDEX.allDrives.f.txt
			grep "${pSingle}" INDEX.allDrives.f.txt
		else
			grep "${patterns[1]}" INDEX.allDrives.f.txt	|
			grep "${patterns[2]}"				|
			grep "${patterns[3]}"				|
			grep "${patterns[4]}"				|
			grep "${patterns[5]}"				|
			grep "${patterns[6]}"				|
			grep "${patterns[7]}"				|
			grep "${patterns[8]}"
		fi >"${tmp}"
		;;
esac


if [ -s "${tmp}" ]
then

	if [ ${pCount} -eq 1 ]
	then
		if [ -s "${tmp}" ]
		then
			#p1="${patterns[1]}"
			awk -v p1="${patterns[1]}" '{
				n=split( $0, filename, "/" ) ;
				if( filename[n] ~ p1 ){
					print $0 ;
				} ;
			}' <"${tmp}" >"${basn}"
			mv "${basn}" "${tmp}"
		fi
	else
		matchBaseName
	fi
fi


if [ -s "${tmp}" ]
then
	wc -l "${tmp}"
	echo ""

	if [ -z "${ftype}" ]
	then
		while [ true ]
		do
			read line
			test -z "${line}" && break
			du -sh "${line}"
		done <"${tmp}" >"${items}" 2>"${xcpt}"
	else
		ftype=$(method3 ${ftype} )
		grep \."${ftype}"\$		<"${tmp}" |
		while [ true ]
		do
			read line
			test -z "${line}" && break
			du -sh "${line}"
		done >"${items}" 2>"${xcpt}"
	fi

	more "${items}"

	countR=$(wc -l "${tmp}" | awk '{ print $1 }' )
	countI=$(wc -l "${items}" | awk '{ print $1 }' )


	if [ ${countI} -eq ${countR} ]
	then
		printf "\n\t %6d  %s\n" ${countI} "${items}"
		postPurge=1
	else
		printf "\n\t %6d  %s\n\t %6d  %s\n" ${countR} "${tmp}" ${countI} "${items}"
		postPurge=0
		printf "\n PARTIAL LIST:  A character in a filename has caused the reporting to abort prematurely.\n"
		printf "\n SUSPECT LINE:\n"
		head -$(expr ${countI} + 1 ) "${tmp}" | tail -1 | awk '{ printf("\t %s\n", $0 ) ; }'

		echo ""
		ls -l "${tmp}"
	fi

	echo ""

	if [  -s "${xcpt}" ]
	then
		ls -l "${xcpt}"
	else
		rm -f "${xcpt}"
	fi

	genCharReports

	if [ ${postPurge} -eq 1 ]
	then
		rm -f "${tmp}"
	fi
else
	printf "\n	NO ITEMS FOUND!\n"
	ls -l "${tmp}"
fi


exit
exit
exit

##############################################################################################
##############################################################################################

###  Defunct code segments

makePatternMatch()
{
	echo "${charList}" | awk 'BEGIN{
		regExp="" ;
	}
	{
		if( $0 != "" ){
			for( i=1 ; i <= NF ; i++ ){
				if( $i ~ /[[:alpha:]]/ ){
					regExp=sprintf("%s[%s%s]", regExp, toupper($i), tolower($i) ) ;
				}else{
					regExp=sprintf("%s%s", regExp, $i ) ;
				} ;
			} ;
		} ;
	}END{
		printf("%s\n", regExp ) ;
	}'
}

explodeString()
{
	#charList=$(echo "${pattern}" | sed 's+[[:alpha:]]*+&\ +g' )
	#charList=$(echo "${pattern}" | sed 's+[[:alpha:]]+&\ +g' )
	charList=$(echo "${pattern}" | sed 's+.+&\ +g' )
	echo "${charList}" >&2
}


method1()
{
	for pattern in $@
	do
		explodeString
		makePatternMatch
	done
}
#method1 $@
### Output - Method 1
#a b * c 1 
#[Aa][Bb]*[Cc]1
#d 2 e ? f 
#[Dd]2[Ee]?[Ff]


method2()
{
	echo "$@" |
	awk '{
		if( $0 != "" ){
			for ( j=1 ; j<= NF ; j++ ){
				n=split( $j , arr , "" ) ;	###  Split word-string into array
				for ( i=1 ; i<=(n) ; i++ ){
					if ( arr[i] ~ /[[:alpha:]]/ ){
						printf("[%s%s]", toupper(arr[i]), tolower(arr[i]) ) ;
					}else{
						printf("%s", arr[i] ) ;
					} ;
				} ;
				printf("\n") ;
			} ;
		} ;
	}'
}
#method2 $@
### Output - Method 2
#[Aa][Bb]*[Cc]1
#[Dd]2[Ee]?[Ff]


