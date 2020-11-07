#!/bin/sh

###     $Id: OS_Admin__PostInstall_UserHomeDirRestructure.sh,v 1.2 2020/11/07 20:09:56 root Exp root $

###     This script will restructure home directory such that all of the following directories, Desktop Documents Downloads Music Pictures Public snap Templates Videos,   will be replaced by a symbolic link to a corresponding ${username}.${dir} on a non-root partition.  This way, all non-profile related files are stored on non-root partition directly, minimizing impact and effort required to recover root disk if anything happens.  There is still the various .* files in the ~${username} directory which need to be dealt with separately.

##################################################################################################
##################################################################################################
###
###
doLink()
{
	### FUTURES:  Add mechanism to test success of separate 'cd' and 'ln' steps.
	( cd /home/${uName}/ ; ln -s ../${uName}.${dir} ./${dir} )

	ls -ld /home/${uName}/${dir} | awk '{ printf("\t %s\n", $0) }'
}	#doLink()

doDir()
{
	mv ${homeSL} ${newDir}
	if [ $? -ne 0 ]
	then
		echo "\n\t FAILED to move '${homeSL}' to desired location at ${newDir} ..."
		ls -ld ${homeSL} | awk '{ printf("\t\t %s\n" , $0 ) }'
		echo "\n\t INVESTIGATE and rectify before re-starting.\n\t Abandoning.\n Bye!\n"
	       	exit 1
	fi

	chmod 775 ${newDir}
	chown ${uName}:${uName} ${newDir}

	ls -ld ${newDir} | awk '{ printf("\t %s\n", $0) }'
}	#doDir()

doThis()
{
	doDir
	doLink
}	#doThis()

doCheckLink()
{
	if [ \( -d ${homeSL} \) -a \( -L ${homeSL} \) ]
	then
		curSL=`readlink ${homeSL} `

		if [ "${curSL}" = "${newDir}" ]
		then
			echo "\t Required symlink at '${homeSL}' already exists:\n\t\t\t `ls -l ${homeSL} | tail -1 ` \n"
			needLINK=0
			if [ ${dBg} -eq 1 ] ; then  echo "DEBUG:	needRESTRUCT = 0" ; fi
			needRESTRUCT=0
		else
			echo "\t Target for existing symlink ${homeSL} not suited to current restructuring logic:\n"
			ls -l ${homeSL} | awk '{ printf("\t\t %s\n" , $0 ) }'

			echo "\n\t Do you wish to maintain existing symlink ? [y|N] => \c" ; read keepL
			if [ -z "${keepL}" ] ; then keepL="N" ; fi
			case ${keepL} in
				y* | Y* )
					echo "\n\t CHOICE to keep non-standard target for directory '${dir}'.  Continuing re-structuring ..."
					if [ ${dBg} -eq 1 ] ; then  echo "DEBUG:	needRESTRUCT = 0" ; fi
					needRESTRUCT=0 ;;
				* )
					echo "\n\t INVESTIGATE (and rectify if required) contents of '${curSL}' before proceeding.\n\t Abandoning.\n Bye!\n"
		        		exit 1
			esac
		fi
	else
		if [ -d ${homeSL} ]
		then
			if [ ${dBg} -eq 1 ] ; then  echo "[doCheckLink] Will restructure '${dir}'" ; fi
			if [ ${dBg} -eq 1 ] ; then  echo "DEBUG:	needRESTRUCT = 1" ; fi
			needRESTRUCT=1
		else
			echo "\n\t File at '${homeSL}' is not a directory as:\n"
			ls -l ${homeSL} | awk '{ printf("\t\t %s\n" , $0 ) }'
			echo "\n\t INVESTIGATE and rectify before re-starting.\n\t Abandoning.\n Bye!\n"
		       	exit 1
		fi
	fi
}	#doCheckLink()

doCheckDir()
{
	needRESTRUCT=0

	if [ -L ${newDir} ]
	then
		echo "\t\t Conflicting symlink exists at '${newDir}':\n\t\t\t `ls -l ${newDir} | tail -1 ` \n"
		echo "\n\t INVESTIGATE and rectify before re-starting.\n\t Abandoning.\n Bye!\n"
	       	exit 1
	else
		if [ -f ${newDir} ]
		then
			echo "\t\t Conflicting file exists at '${newDir}':\n\t\t\t `ls -l ${newDir} | tail -1 ` \n"
			echo "\n\t INVESTIGATE and rectify before re-starting.\n\t Abandoning.\n Bye!\n"
       			exit 1
		else
			if [ -d ${newDir} ]
			then
				echo "\t\t Conflicting directory exists at '${newDir}':\n\t\t\t `ls -ld ${newDir} | tail -1 ` \n"
				echo "\n\t INVESTIGATE and rectify before re-starting.\n\t Abandoning.\n Bye!\n"
	       			exit 1
			else
				if [ ${dBg} -eq 1 ] ; then  echo "[doCheckDir] Will restructure '${dir}'" ; fi
				if [ ${dBg} -eq 1 ] ; then  echo "DEBUG:	needRESTRUCT = 1" ; fi
				needRESTRUCT=1
			fi
		fi
	fi
}	#doCheckDir()

doRestructure()
{
	COM="doThis"
	if [ ${dBg} -eq 1 ] ; then  echo "\t\t [doRestructure] ${COM}" ; fi
	eval ${COM}
}	#doRestructure()



##################################################################################################
##################################################################################################
###
###
doRestructureDirs()
{
	tester=`cd /home/${uName} ; ls `

	if [ -z "${tester}" ]
	then
		echo "\n\t User '${uName}' has never logged in."
		echo "\t The system has not yet created the basic environment for that user."
		echo "\t Unable to proceed for '${uName}' ..."
	else
		echo "\n\t Contents of HOME directory for user '${uName}':\n"

		( cd /home/${uName} ; ls -l | tail -n +2 | awk '{ printf("\t\t %s\n", $0 ) }' )

		rsFail=0

		for dir in Desktop Documents Downloads Music Pictures Public snap Templates Videos
		do
			stepSUCCESS=0
			echo ""
			case `hostname` in
				OasisMega1 )
					newDir="/DB001_F2/home/${uName}.${dir}"
					homeSL="/home/${uName}/${dir}"
					;;
				* )
					newDir="/home/${uName}.${dir}"
					homeSL="/home/${uName}/${dir}"
					;;
			esac

			doCheckLink

			if [ ${needRESTRUCT} -eq 1 ]
			then
				doCheckDir
			fi

			if [ ${needRESTRUCT} -eq 1 ]
			then
				doRestructure
			fi
		done

		if [ ${rsFail} -eq 0 ]
		then
			if [ ${dBg} -eq 1 ] ; then  
				echo "\n\t Completed restructuring ..."
			else
				echo "`date`\n## User directory environment was re-structured using\n##\t'`basename $0 `'\n## at the above date and time." >${rsDate}
				echo "\n\t Completion timestamp saved as '${rsDate}' ..."
        		fi
		fi
	fi
}


##################################################################################################
##################################################################################################
###
###
#123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+


dBg=0
if [ ${dBg} -eq 0 ] ; then  echo "\n\t NOTE:  Option '--debug' will give additional messaging at critical\n\t points and will suppress creation of the timestamp file which is\n\t used to flag that restructuring was already completed.\n" ; fi

cd /home

echo "\n\t Contents of '/home' directory:\n"

ls -l | awk '{ printf("\t\t %s\n", $0 ) }'

for uName in `ls | grep -v '\.' `
do
	case ${uName} in
		*.* )	;;
		* )
			echo "\n====================================================================================================\n ** uName= ${uName} ..."

			if [ \( ! -L ${uName} \) -a \( -d ${uName} \) ]
			then
				tester=`grep "${uName}:" /etc/passwd | head -1 `
				if [ -n "${tester}" ]
				then
					echo "\n\t Re-structure directories for user '${uName}' ? [y|N] => \c"
					read ans
					if [ -z "${ans}" ] ; then  ans="N" ; fi
					case ${ans} in
						y* | Y* )
							rsDate="/home/${uName}/.RestructuredDirs_1"

							if [ -e ${rsDate} ]
							then
								echo "\n\t Directory structure for user '${uName}' was already completed on => `head -1 ${rsDate} ` ..."
							else
								COM="doRestructureDirs"
if [ ${dBg} -eq 1 ] ; then  echo "\t\t [MAIN] ${COM} ..." ; fi
								eval ${COM}
							fi
							;;
						* )	echo "\t\t ... Ignored."
							;;
					esac
				fi
			fi
			;;
	esac
done

echo "\n Done.\n"

exit 0
exit 0
exit 0
