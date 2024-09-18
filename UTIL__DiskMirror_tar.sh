#!/bin/sh

TMP=/tmp/`basename "$0" ".sh" `.tmp.$$

####################################################################################################
###
###	Script which operates in 2 modes:
###		- create mirror of specified partition (root) 
###		- reclaim specified partition (root) from mirror
###
###	Convention used for expected values for ${partition} is 'F[1-8]'
###		Namely, partition full label is DB001_F#.
###		Mirroring from    /DB001_F3  onto  /site/DB002_F3 , or
###		Reclaim from      /site/DB002_F3  onto  /DB001_F3 .
###
####################################################################################################
#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+

partMirror()
{
	cd "${prefSrc}_${partition}" 
	if [ $? -ne 0 ]
	then
		echo "\n\t Unable to set '${prefSrc}_${partition}' as SOURCE directory for partition mirroring.\n Bye!\n" ; exit 1
	fi

	COM="( cd '${prefSrc}_${partition}' ; nice -n 17 tar cf - . ) | ( cd '${prefMir}_${partition}' ; nice -n 17 tar xvpf - )"
	echo 	"echo \"COMMAND:  ${COM}\"\n\n ${COM}" >${TMP}.run
	chmod 750 ${TMP}.run

	if [ ${doVerbose} -eq 1 ]
	then
		cat ${TMP}.run | awk '{ printf(" SCRIPT| %s\n", $0) ; }'
		ls -l ${TMP}.run
		echo
	fi
}

doMirror=1
doIt=0
doVerbose=0
verb=0

while [ $# -gt 0 ]
do
	case $1 in
		--mirror ) doMirror=1 ; shift ;;
		--reclaim) doMirror=2 ; shift ;;
		--verbose ) doVerbose=1 ; verb="--verbose" ; shift ;;
		--force )  doIt=1 ; shift ;;
		--* ) echo "\n\t Invalid parameter used on command line.\n Bye!\n" ; exit 1 ;;
		* )
			if [ $# -gt 1 ]
			then
				echo "\n\t May only specify one partition ID on the command line.\n Bye!\n" ; exit 1
			fi
			partition="$1"
			shift
			break
			;;
	esac
done


if [ ${doMirror} -eq 1 ]
then
	prefSrc="/DB001"
	prefMir="/site/DB002"
fi
if [ ${doMirror} -eq 2 ]
then
	prefSrc="/site/DB002"
	prefMir="/DB001"
fi

if [ ! -d ${prefSrc}_${partition} ]
then
	### FUTURES:  add device comparison with root to ensure it is distinct and mounted
	echo "\n\t Invalid SOURCE partition specified [${prefSrc}_${partition}]. Bye!\n" ; exit 1
	devSrc=`df ${prefSrc}_${partition} | awk '{ print $1 }' `
fi
if [ ! -d ${prefMir}_${partition} ]
then
	### FUTURES:  add device comparison with root to ensure it is distinct and mounted
	echo "\n\t Invalid TARGET partition specified [${prefMir}_${partition}]. Bye!\n" ; exit 1
	devMir=`df ${prefMir}_${partition} | awk '{ print $1 }' `
fi


#if [ "${devSrc}" == "${devMir}" ]
#then
#	echo "\n\t One of the two specified disks is not mounted. Correct before re-attempting. Bye!\n" ; exit 1
#fi


rm -f ${TMP}
df >${TMP}
pRoot=`cat ${TMP} | awk -v pat="_${partition}\$" '{ if( $6 == "/" ){ print $1 } ; }' `

pSrc=`cat ${TMP} | awk -v pat="${prefSrc}_${partition}\$" '{ if( $6 ~ pat ){ print $1 } ; }' `
pMir=`cat ${TMP} | awk -v pat="${prefMir}_${partition}\$" '{ if( $6 ~ pat ){ print $1 } ; }' `

if [ "${pSrc}" = "${pRoot}" ];
then
	echo "\n\t SOURCE partition ${prefSrc}_${partition} is not mounted!\n Bye!\n" ; exit 1
fi
if [ "${pMir}" = "${pRoot}" ];
then
	echo "\n\t TARGET partition ${prefMir}_${partition} is not mounted!\n Bye!\n" ; exit 1
fi

partMirror

if [ ${doIt} -eq 1 ]
then
	#time ${verb} ${TMP}.run
	time ${TMP}.run
else
	time echo "execute partMirror:  ${prefSrc}_${partition} -> ${prefMir}_${partition}"
fi

exit 0
exit 0
exit 0


