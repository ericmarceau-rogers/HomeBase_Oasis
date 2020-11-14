#!/bin/sh

###	$Id: $
###	Description TBD

echo "\n\t Logic for in this script needs to be revisited and confirmed before using.\n Bye!\n" ; exit 1

MARKER_FILES="/etc/issue /etc/issue.net /etc/lsb-release /etc/os-release"

if [ "$1" = "--force" ]
then
	shift
else
	echo "\n\t This script is dangerous.  Do not run without first reviewing code."
	echo "\n\t Script will clobber the following files with versions from OasisMega1:\n"
	for file in `echo ${MARKER_FILES} `
	do
		echo "\t\t ${file}"
	done
	echo ""
	exit 1
fi

SHOWF=1

if [ `hostname` = "OasisMega1" ]
then
	echo "\n Master Host mode ... reviewing contents of master files ..."
	#echo "\n\t Should NOT be run from OasisMega1 (Master host).\n\n Bye!\n" ; exit 1
	FilesFROM=""
	if [ -n "$1" ]
	then
		COMPARE="${1}" ; shift
	fi
else
	while [ $# -gt 0 ]
	do
		case $1 in
			--copy )
				SHOWF=0 ; shift
				;;
			--show )
				SHOWF=1 ; shift
				;;
			* )
				echo "\n\t ONLY after reviewing the script and what it does, you must also specify one of the '--show' or '--copy' options.\n" ; exit 1
				;;
		esac
	done

	FilesFROM="${MROOT}/DB001_F1"
fi

#############################################################################################
#############################################################################################

ShowFiles()
{
	for MarkerFile in ${MARKER_FILES}
	do
		echo "\n#####################################################################"
		echo "\t ${FilesFROM}${MarkerFile}:\n"
		cat ${FilesFROM}${MarkerFile}

		if [ -n "${COMPARE}" ]
		then
			echo "\t =================================================================================="
			echo "\t ${MROOT}/${COMPARE}${MarkerFile}:\n"
			cat ${MROOT}/${COMPARE}${MarkerFile}
		fi

	done
	echo "\n#####################################################################"
}

CopyFiles()
{
	FilesTO=""

	for MarkerFile in ${MARKER_FILES}
	do
		echo "\n#####################################################################"
		echo "\t ${FilesFROM}${file}:\n"
		cp -p ${FilesFROM}${MarkerFile} ${FilesTO}${MarkerFile}
		ls -l ${FilesTO}${MarkerFile}
	done
	echo "\n#####################################################################"
}


if [ ${SHOWF} -eq 1 ]
then
	ShowFiles
else
	CopyFiles
fi


exit 0
exit 0
exit 0
