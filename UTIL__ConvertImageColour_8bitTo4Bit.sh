#!/bin/sh

###	PREREQUISITE:	'netpbm' package

defaultUID="1000"

if [ $# -eq 0 ] ; then  echo "\n\t Missing expected parameter providing name of '*.png' file to convert to 4-bit (16 colour) file.\n Bye!\n" ; exit 1 ; fi

for file in $*
do
	INPUT="${file}"
	if [-s "${file}"]
	then
		DIR=`dirname "${INPUT}" `
		NEW=${DIR}/`basename "${INPUT}" ".png" `_16.png

		case "${INPUT}" in
			*.png ) ;;
			* ) echo "\n\t This utility intended to convert '*.png' file to 4-bit (16 colour) file.\n Bye!\n" ; exit 1 ;;
		esac

		dat=`grep ":${defaultUID}:" /etc/passwd | awk -F ":" '{ if( $3 == 1000 ){ print $1, $3 } ; }' `

		User=`echo "${dat}" | awk '{ print $1 }' `
		GID=`echo "${dat}" | awk '{ print $2 }' `

		Group=`grep ":${GID}:" /etc/group | awk -F ":" -v gid="${GID}" '{ if( $3 == gid ){ print $1 } ; }' `

		pngtopnm "${INPUT}" | pnmquant 16 | pnmtopng > "${NEW}"

		chown ${User}:${Group} "${NEW}"
		ls -l "${INPUT}" "${NEW}"
	else
		echo "\n\t File '${file}' is empty.  No action taken ..."
	fi
done

echo "\n\t All required actions complete. \n Bye!\n"

exit 0
exit 0
exit 0
