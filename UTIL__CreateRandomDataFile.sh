#!/bin/sh

#############################################################################################
###
###	$Id: UTIL__CreateRandomDataFile.sh,v 1.2 2022/08/17 19:57:09 root Exp $
###
###	Script to create file containing randomized data for specified size.
###
#############################################################################################

echo "\n\t Select size of file to create:\n
		 [1] 1 MB
		 [2] 16 MB
		 [3] 256 MB
		 [4] 2 GB
		 [5] 10 GB\n
	 Enter selection [1-5|q] => \c"

read response
if [ -z "${response}" ]
then
	response="Q"
fi

case ${response} in
	1 )	LBL="1M"	; SIZE="1M" ; count=1 ;;
	2 )	LBL="16M"	; SIZE="1M" ; count=16 ;;
	3 )	LBL="256M"	; SIZE="1M" ; count=256 ;;
	4 )	LBL="2G"	; SIZE="1M" ; count=2048 ;;
	5 )	LBL="16G"	; SIZE="1M" ; count=16384 ;;
	q* | Q* | * )	echo "\n Bye!\n" ; exit 1 ;;
esac

#64M count=16

OUTPUT=RANDOM.ephemeral_data.${LBL}

{
	echo ""
	COM="dd iflag=fullblock bs=${SIZE} count=${count} if=/dev/urandom of=${OUTPUT} 2>&1"
	echo "Doing:  ${COM} ..."
	eval ${COM}
	echo ""
	ls -lh ${OUTPUT}
	echo ""
} | awk '{ printf("\t %s\n", $0 ) ; }'
