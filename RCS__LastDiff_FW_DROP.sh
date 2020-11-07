#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: RCS__LastDiff_FW_DROP.sh,v 1.5 2020/09/04 01:26:38 root Exp $
###
###	This script will report the difference between the current script and the last checked-in version for it.
###
####################################################################################################

procSTRING()
{
	if [ -n "${string}" ]
	then
		awk -v string="${string}" -v last="${last}" 'BEGIN{ del=1 ; }{
			if ( $0 ~ string ) {
				if ( index($0,">") == 1 ) {
					if ( last == 0 ) {
						printf("%s\n", $0 ) ;
					}else{
						if ( del == 0 ) {
							printf("%s\n", $0 ) ;
						}else{
							printf("\n%s\n", $0 ) ;
						} ;
					} ;
				}else{
					if ( last == 0 ) {
						printf("%s\n", $0 ) ;
					} ;
				} ;
				del=0;
			} ;
			del=index($0, "---") ;
		}'
	else
		awk -v last="${last}" '{
				if ( index($0,">") == 1 ) {
					if ( last == 0 ) {
						printf("%s\n", $0 ) ;
					}else{
						if ( del == 0 ) {
							printf("%s\n", $0 ) ;
						}else{
							printf("\n%s\n", $0 ) ;
						} ;
					} ;
				}else{
					if ( last == 0 ) {
						printf("%s\n", $0 ) ;
					} ;
					del=0;
				} ;
				del=index($0, "---") ;
		}'
	fi
}	#procSTRING()

procNoDROP()
{
	#echo "\n\t OVERRIDE:  '--last' ignored ...\n" >&2
	#last=0
	rcsdiff -kkvl "${script}" | procSTRING
}	#procNoDROP()

procDROP()
{
	procSTRING <${TMP}
}	#procDROP()


#####################################################################################################
#####################################################################################################

DBG=0

TMP=/tmp/`basename "$0" ".sh" `.tmp
rm -f ${TMP}

last=0
drop=0
doString=0
string=""

while [ $# -gt 0 ]
do
	case "$1" in
	--drop )   drop=1 ; TARGET="DROP" ; shift ;;
	--accept ) drop=1 ; TARGET="ACCEPT" ; shift ;;
	--reject ) drop=1 ; TARGET="REJECT" ; shift ;;
	--last )   last=1 ; shift ;;
	--comp )   last=0 ; shift ;;
	--script ) script="$2" ; shift ; shift ;;
	--string ) doString=1 ; shift ; string="$@" ; break ;;
	* ) echo "\n\t Invalid parameter '$1'.\n\n\t Only valid parameters:  --string {filename} [--last|--comp] [--string {remainderOfline}]\n  Bye!\n" >&2 ; exit 1 ;;
	esac
done

if [ -z "${script}" ] ; then  echo "\n\t Missing value for '--script' parameter.\n Bye!\n" >&2 ; exit 1 ; fi
if [ ${DBG} -eq 1 ] ; then  echo "script= '${script}'" >&2 ; fi

if [ \( ${doString} -eq 1 \) -a \( -z "${string}" \) ] ; then  echo "\n\t Missing value for '--string' parameter.\n Bye!\n" >&2 ; exit 1 ; fi
if [ ${DBG} -eq 1 ] ; then  echo "string= '${string}'" >&2 ; fi

rm -f ${TMP}
if [ ${drop} -eq 1 ]
then
	rcsdiff -kkvl "${script}" 2>>/dev/null | awk -v target="-j ${TARGET}" '{ if ( $0 ~ /target/ ){ print $0 ; } ; }' >${TMP}
fi

if [ -s ${TMP} ]
then
	procDROP
else
	procNoDROP
fi
rm -f ${TMP}
