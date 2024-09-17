#!/bin/sh

TMP=/tmp/`basename "$0" ".sh" `.tmp

Filt=0
showMin=0
showAlias=0
showSignature=0
showBasic=0
doSrch=0
sParm=""

while [ $# -gt 0 ]
do
	case $1 in
		--min )   Filt=1 ; showMin=1 ; showSignature=0 ; showBasic=0 ; shift ;;
		--alias ) Filt=1 ; showAlias=1 ; shift ;;
		--sign )  Filt=1 ; showSignature=1 ; showBasic=0 ; shift ;;
		--basic ) Filt=1 ; showBasic=1 ; showMin=1 ; showSignature=0 ; shift ;;
		--search ) doSrch=1 ; sParm="$2" ; shift ; shift ;;
		* ) echo "\n\t Invalid option used on command line.  Unable to proceed.\n Bye!\n" ; exit 1 ;;
	esac
done

#alias:
#Bit
#firmware:

infoAll()
{
	modinfo ${module}
}


infoFiltered()
{
	modinfo ${module} 2>&1 | awk -v mMin="${showMin}" -v mBasic="${showBasic}" -v mSign="${showSignature}" -v mAlias="${showAlias}" -v gSrc="${doSrch}" -v sP="${sParm}" '{
		if( $1 == "name:" ){
			print $0 ;
			mdString=$2 ;
		} ;
		if( $1 == "filename:" ){
			print $0 ;
			fnString=$2 ;
		} ;
		if( $1 == "version:" ){ print $0 ; } ;

		if( $1 == "description:" ){
			print $0 ;
			dsString=substr($0,17) ;
		} ;

		if( mBasic == 1 ){
			if( $1 == "author:" ){ print $0 ; } ;
			if( $1 == "license:" ){ print $0 ; } ;
			if( $1 == "srcversion:" ){ print $0 ; } ;
			if( $1 == "depends:" ){ print $0 ; } ;
			if( $1 == "retpoline:" ){ print $0 ; } ;
			if( $1 == "intree:" ){ print $0 ; } ;
			if( $1 == "vermagic:" ){ print $0 ; } ;
			if( $1 == "parm:" ){ print $0 ; } ;
		} ;
		
		if( mSign == 1 ){
			if( $1 == "sig_id:" ){ print $0 ; } ;
			if( $1 == "signer:" ){ print $0 ; } ;
			if( $1 == "sig_key:" ){ print $0 ; } ;
			if( $1 == "sig_hashalgo:" ){ print $0 ; } ;
			if( $1 == "signature:" ){ print $0 ; } ;
			dat=substr($1,3,1) ;
			if( dat == ":" ){
				print $0 ;
			} ;
		} ;

		if( mAlias == 1 ){
			if( $1 == "alias:" ){ print $0 ; } ;
		} ;

		if( $1 != "filename:" && $1 != "description:" && $1 == "version:" && $1 != "author:" && $1 != "license:" && $1 != "srcversion:" && $1 != "depends:" && $1 != "retpoline:" && $1 != "intree:" && $1 != "name:" && $1 != "vermagic:" && $1 == "parm:" && $1 != "sig_id:" && $1 != "signer:" && $1 != "sig_key:" && $1 != "sig_hashalgo:" && $1 != "signature:" && $1 != "parm:" && $1 != "alias:" ){
			dat=substr($1,3,1) ;
			if( dat != ":" ){
				print $0 ;
			} ;
		} ;
	}END{
		if( gSrc == 1 ){
			if ( index(fnString,sP) != 0 || index(dsString,sP) != 0 ){
				printf("MATCH[%s]%s\nMATCH[%s]%s\n\n", mdString , fnString , mdString, dsString ) | "cat 1>&2" ;
			} ;
		} ;
	}'
}

###	sed -e 's/^[ \t]*//'


for module in `lsmod | awk '{print $1 }' | tail -n +2 | sort `
do
	echo "\n========================================\n${module}|MODULE"
	if [ ${Filt} -eq 1 ]
	then
		infoFiltered
	else
		infoAll
	fi
done
#done | awk '{ print $1 }' | grep -v '^[0-9A-F][0-9A-F]:' | sort | uniq 


exit 0
exit 0
exit 0


#filename:
#description:
#author:
#license:
#srcversion:
#depends:
#retpoline:
#intree:
#name:
#vermagic:

#sig_id:
#signer:
#sig_key:
#sig_hashalgo:
#signature:
#parm:




