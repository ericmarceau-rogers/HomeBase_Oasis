#!/bin/sh


error()
{
	echo "\n\t ${msg}  [ --file | --dir | --dev ] {target_identifier} \n Bye!\n" ; exit 1
}

if [ $# -eq 0 ] ; then  msg="Missing option required for command line.  Available options:"
	error ; fi

MODE=""
TARGET=""
while [ $# -gt 0 ]
do
	case ${1} in
		--eval )	MODE="-c" ; shift ;;
		--details )	MODE="-v" ; shift ;;
		--file )	FILENAME="${2}" ; shift ; shift ;
				if [ -f "${FILENAME}" ]
				then
					TARGET="${FILENAME}"
				fi
				break
				;;
		--dir )		DIRECTORY="${2}" ; shift ; shift ;
				if [ -d "${DIRECTORY}" ]
				then
					TARGET="${DIRECTORY}"
				fi
				break
				;;
		--dev )		DEVICE="${2}" ; shift ; shift ;
				if [ -b "${DEVICE}" ]
				then
					TARGET="${DEVICE}"
				fi
				break
				;;
		* ) msg="Invalid option used on the command line.  Only options are:" ; error ;;
	esac
done

if [ -n "${TARGET}" ]
then
	eval e4defrag ${MODE} \"${TARGET}\"
fi


exit 0
exit 0
exit 0


