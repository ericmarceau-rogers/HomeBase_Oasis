#!/bin/sh

###	Basic functionality - split on Braces

BASE=`basename "$0" ".sh" `
TMP="/tmp/tmp.$$.${BASE}"

{
	if [ -n "${1}" ]
	then
		cat ${1}
	else
		cat
	fi | sed 's+^\t++' | sed 's+^[\ ]++'
} |
	awk 'BEGIN{
		splitter=";" ;
	}{
		rem=$0 ;
		if( rem != "" || rem !~ /\s*/ ){
			n=index( rem, "{" )
			while( n != 0 ){
				beg=substr( rem, 1, n ) ;
				print beg ;
				rem=substr( rem, n+1 ) ;
				n=index( rem, "{" ) ;
			} ;
			if( rem != "" || rem !~ /\s*/ ){
				print rem ;
			} ;
		} ;
	}' |
	awk 'BEGIN{
		splitter=";" ;
	}{
		rem=$0 ;
		if( rem != "" || rem !~ /\s*/ ){
			n=index( rem, "}" )
			while( n != 0 ){
				beg=substr( rem, 1, n-1 ) ;
				print beg ;
				print "}" ;
				rem=substr( rem, n+1 ) ;
				n=index( rem, "}" ) ;
			} ;
			if( rem != "" || rem !~ /\s*/ ){
				print rem ;
			} ;
		} ;
	}'

		
