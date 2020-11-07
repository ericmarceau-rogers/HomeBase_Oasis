#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: CODING__ExtractIpAddresses.sh,v 1.2 2020/08/17 23:40:48 root Exp $
###
###	This script extracts IP address/mask values from IPTABLES rules in scripts.
###
####################################################################################################


TMP=/tmp/`basename "$0" ".sh" `.tmp
rm -f ${TMP}

save=0
addrONLY=1

while [ $# -gt 0 ]
do
	case $1 in
		--save )	save=1     ; shift ;;
		--direction )	addrONLY=0 ; shift ;;
		--file ) 	INPUT="$2" ; shift ; shift ;;
		* ) echo "\n\t Invalid parameter '$1' used on command line.  Only options: --file {filename} [ --direction ] [--save] '.\n Bye!\n" ; exit 1 ; 
;;
	esac
done

if [ -z "${INPUT}" ] ; then  echo "\n\t MISSING:  Require name of file to be specified with '--file' parameter.\n Bye!\n" ; exit 1 ; fi

awk -v addrOnly="${addrONLY}" -v save="${save}" '{	
	if ( save == 1 ){
		Spos=index($0, "-S") ;
		if ( Spos != 0 ){
			split(substr($0, Spos+3), x) ;
			if ( addrOnly == 1 ){
				print x[1] ;
			}else{
				print "S", x[1] ;
			} ;
		} ;
		Spos=index($0, "-D") ;
		if ( Spos != 0 ){
			split(substr($0, Spos+3), x) ;
			if ( addrOnly == 1 ){
				print x[1] ;
			}else{
				print "D", x[1] ;
			} ;
		} ; 
	}else{
		Spos=index($0, "--source") ;
		if ( Spos != 0 ){
			split(substr($0, Spos+9), x) ;
			if ( addrOnly == 1 ){
				print x[1] ;
			}else{
				print "S", x[1] ;
			} ;
		} ;
		Spos=index($0, "--destination") ;
		if ( Spos != 0 ){
			split(substr($0, Spos+14), x) ;
			if ( addrOnly == 1 ){
				print x[1] ;
			}else{
				print "D", x[1] ;
			} ;
		} ; 
	} ;
}' <${INPUT}


exit 0
exit 0
exit 0
