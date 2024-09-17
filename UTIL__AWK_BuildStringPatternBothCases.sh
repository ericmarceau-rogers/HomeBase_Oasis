#!/bin/sh

	awk 'BEGIN{
		remPat="" ;
		outPat="" ;
		indx=0 ;
	}{
		if( remPat=="" ){
			remPat=$0 ;
		} ;

		while( length(remPat) > 0 ){
			nextC=substr(remPat,1,1) ;
			remPat=substr(remPat,2) ;

			#DBG# print "remPat=", remPat ;
			#DBG# indx=indx++ ;
			#DBG# print "indx=", indx ;

			switch( nextC ){
				#case /[[:lower:]]/ :	NOTE: Standard regexp notation not recognized
				#case /[:lower:]/ :	NOTE: Standard regexp notation not recognized
				case /[:a-z:]/ :
					cPat=sprintf("[%s%s]", nextC, toupper(nextC) ) ;
					break ;
				#case /[[:upper:]]/ :
				#case /[:upper:]/ :
				case /[:A-Z:]/ :
					#cPat=sprintf("[%s%s]", nextC, tolower(nextC) ) ;
					cPat=sprintf("[%s%s]", tolower(nextC), nextC ) ;
					break ;
				case /[:<>*?.$~{}()]/ :
					cPat=sprintf("[%s]", nextC ) ;
					break ;
				case /\]/ :
				case /\[/ :
					cPat=sprintf("[\\%s]", nextC ) ;
					break ;
				default:
					cPat=nextC ;
					break ;
			} ;
			outPat=sprintf("%s%s", outPat, cPat ) ;
			#DBG# print "outpat=", outPat, "\n" ;
		} ;
	}END{
		printf("%s\n", outPat ) ;
	}'

