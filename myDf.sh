#!/bin/sh
#########################################################################
###
###	$Id: myDf.sh,v 1.4 2020/11/14 02:54:56 root Exp $
###
###	Report output of "df" command such that drive labels are sorted alphabetically and all mounted drives are at bottom.  Option '--all' reports non-disk filesystems and '--debug' reports raw input before displaying expected report.
###
#########################################################################

#FUTURES: redo list so that root "/" is reported just before others and with its own drive label.

#DevStat=PROD
#2018-03-18

TMP=/tmp/`basename $0 ".sh"`.$$

onlyHard=1
debug=0
mirrors=0

if [ $# -gt 0 ]
then
	case $1 in
		--mirrors )	mirrors=1	; shift ;;
		--all )		onlyHard=0	; shift ;;
		--debug )	debug=1		; shift ;;
		* ) ;;
	esac 
fi

rm -f ${TMP}.*
df -h >${TMP}.raw

header=`head -1 ${TMP}.raw `
echo "\n\t${header}"									> ${TMP}.2

if [ ${mirrors} -eq 1 ]
then
	tail -n +2	${TMP}.raw | sort -k1,1 | sort -k6,6				> ${TMP}.1
else
	tail -n +2	${TMP}.raw | sort -k6						> ${TMP}.1
	if [ ${onlyHard} != 1 ]
	then
		grep -v '/sd' ${TMP}.1 | grep -v '/site' | sort -n -k1,1 | awk '{ printf("\t%s\n", $0 ) }'	>>${TMP}.4 

		#/dev/sda1       288G   16G  257G   6% /site/DB001_F1
		cat ${TMP}.4 | awk 'BEGIN{ INDX=0 }{
			REF=substr($1,1,4) ;
			if( REF == INDX ){
				printf("\t%-12s %7s %5s %5s %4s %s\n", $1, $2, $3, $4, $5, $6 ) ;
			}else{
				printf("\n\t%-12s %7s %5s %5s %4s %s\n", $1, $2, $3, $4, $5, $6 ) ;
				INDX=REF ;
			} ;
		}'									>>${TMP}.2

		echo "\n\t${header}"							>>${TMP}.2
	fi
fi

if [ ${debug} -eq 1 ]
then
	cat ${TMP}.1
	echo "=========================================\n"
fi

if [ ${mirrors} -eq 1 ]
then
	grep '/sd'	${TMP}.1 							>>${TMP}.3

	cat ${TMP}.3 | awk '{ 
		n=split($6,var,"/") ;
		split(var[n],dar,"_") ;
		REF=substr(dar[2],2) ; if( length(REF) == 0 ){ REF=0 } ;
		printf("%s|%s|%s\n", REF, $6, $0 ) ;
	}' | sort | awk -F \| '{ printf("%s\n", $3 ) }' |
	awk 'BEGIN{ INDX=-1 }{
		p=split($6,var,"/") ;
		split(var[p],dar,"_") ;
		REF=substr(dar[2],2) ; if( length(REF) == 0 ){ REF=0 } ;
		if( REF == INDX ){
			printf("\t%-12s %7s %5s %5s %4s %s\n", $1, $2, $3, $4, $5, $6 ) ;
		}else{
			printf("\n\t%-12s %7s %5s %5s %4s %s\n", $1, $2, $3, $4, $5, $6 ) ; 
			INDX=REF ;
		} ;
	}'										>>${TMP}.2 
	echo "\n\t${header}\n"								>>${TMP}.2
else
	grep '/sd'	${TMP}.1 | grep -v '/site'					>>${TMP}.3
	grep '/sd'	${TMP}.1 | grep    '/site'					>>${TMP}.3

	cat ${TMP}.3 | awk 'BEGIN{ INDX=0 }{
		n=split($6,var,"/") ;
		split(var[n],dar,"_") ;
		REF=substr(dar[1],5) ;
		if( REF == INDX ){
			printf("\t%-12s %7s %5s %5s %4s %s\n", $1, $2, $3, $4, $5, $6 ) ;
		}else{
			printf("\n\t%-12s %7s %5s %5s %4s %s\n", $1, $2, $3, $4, $5, $6 ) ; 
			INDX=REF ;
		} ;
	}'										>>${TMP}.2 
	echo "\n\t${header}\n"								>>${TMP}.2
fi

cat ${TMP}.2

rm -f ${TMP}.*
