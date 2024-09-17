#!/bin/bash

###	Script to translate "cryptic" USB device reporting into human-relatable description

### Typical log entry when trying to debug
#[ 439.463843] usb 1-1: New USB device found, idVendor=0634, idProduct=5600, bcdDevice= 1.00

idVendor="-1"
idProduct="-1"

while [ $# -gt 0 ]
do
	case "${1}" in
		"--all" ) usb-devices ; exit ;;
		"--idVendor" ) idVendor="${2}" ; shift ; shift ;;
		"--idProduct" ) idProduct="${2}" ; shift ; shift ;;
		"--debug" ) dbg=1 ; shift ;;
		"--test1" )
			### Hardcoded local test case #1 - Single component (USB Mouse)
			idVendor="046d" ;
			idProduct="c077" ;
			shift ;
			;;
		"--test2" )
			### Hardcoded local test case #2 - Multiple component (USB ports)
			idVendor="1d6b" ;
			idProduct="0001" ;
			shift ;
			;;
	esac
done

if [ "${idVendor}" = "-1" ] || [ "${idProduct}" = "-1" ]
then
	printf "\n\t Script requires reported values for both --idVendor {} and --idProduct {} \n\n" ; exit 1
fi

usb-devices |
awk -v dbg=${dbg} -v idvendor="${idVendor}" -v idproduct="${idProduct}" 'BEGIN{
	captureON=0 ;
	split( "", details) ;
	split( "", size) ;
	split( "", descr) ;
	indx=0 ;
	lastgood=0 ;
	keep=0 ;
}{
	if( NF == 0 ){
		if( keep == 1 ){
			size[indx]=attrib ;	### save number of attribute lines
			if( dbg == 1 ){
				printf("\n\t attrib = %d\n", attrib ) | "cat 1>&2" ;
			} ;
			lastgood=indx ;
		}else{
			indx=lastgood ;		### reset index to discard any details captured for last item
		} ;
		keep=0 ;
		captureON=0 ;
	} ;

	if( index( $0, "T:" ) == 1 ){		### First line of every BUS item
		captureON=1 ;
		indx++ ;
		if( dbg == 1 ){
			printf("\n\t indx = %d\n", indx ) | "cat 1>&2" ;
		} ;
		attrib=0 ;
		size[indx]=0 ;
	};

	if( captureON == 1 ){
		attrib++ ;
		if( dbg == 1 ){
			printf("\t\t attrib = %d\n", attrib ) | "cat 1>&2" ;
		} ;
		details[indx,attrib]=$0 ;		### capture raw line for reporting

		#P:  Vendor=046d ProdID=c077 Rev=72.00
		if( index( $0, "P:" ) == 1 ){
			split( $2, vend, "=" ) ;
			vendor=vend[2] ;
			split( $3, prod, "=" ) ;
			product=prod[2] ;

			if( dbg == 1 ){
				printf("\t\t  vendor = %s      idvendor = %s \n", vendor, idvendor ) | "cat 1>&2" ;
				printf("\t\t product = %s     idproduct = %s \n", product, idproduct ) | "cat 1>&2" ;
			} ;

			if( vendor == idvendor && product == idproduct ){
				keep=1 ;
			} ;
		} ;

		#S:  Manufacturer=Logitech
		if( $2 ~ /Manufacturer/ ){
			split( $0, mfg, "=" ) ;
			manufacturer=mfg[2] ;
			descr[indx]=sprintf("COMPONENT:  %s", manufacturer ) ;
		} ;

		#S:  Product=USB Optical Mouse
		if( $2 ~ /Product/ ){
			split( $0, prod, "=" ) ;
			product=prod[2] ;
			descr[indx]=sprintf("%s, %s", descr[indx], product ) ;
		} ;
	} ;
}END{
	if( keep == 0 ){
		indx-- ;
	} ;
	for( i=1 ; i <= indx ; i++ ){
		if( size[i] > 0 ){
			if( indx > 1 ){
				printf("\n==========================================================================\n" ) ;
			} ;
			print descr[i] ;
			for( j=1 ; j <= size[i] ; j++ ){
				print details[i,j] ;
			} ;
		} ;
	} ;
}'


exit 

