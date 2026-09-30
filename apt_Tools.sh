#!/bin/sh

TMP=`basename $0 ".sh"`.$$.tmp

cd /var/cache/apt/archives

probingMenu()
{
	echo "\n\t Select package probing approach\n
	 [a]	aptitude	why {packBaseName}
				* determine if ANY dependency and, if so, list first dependency encountered
				* why it was first installed, immediately dependent packages (directly referenced)
				  & will identify if manually installed

	 [b]	apt-cache	showpkg {packBaseName}
				* all dependants, recursive

	 [c]	apt-cache	rdepends --installed {packBaseName}
				* immediately dependent packages (directly referenced)

	 [d]	aptitude	-v --show-summary=all-packages why {packBaseName}
				* why it was first installed, immediately dependent packages (directly referenced) & will identify if manually installed
	 [e]	aptitude	-s purge {packBaseName}
				* what would happen if package is removed

	 [f]	apt-rdepends	-r {packBaseName} 
				* immediately dependent packages (directly referenced)     [alternate method] \n\n\t Enter choice of package probing => \c"
}

probingMenu

while read packageProbingStyle
do

	if [ -z "${packageProbingStyle}" ]
	then
		echo "\n\t Bye!\n"
		exit 0
	fi

	case ${packageProbingStyle} in
		a* | A* )	COM="aptitude why"
				;;
		b* | B* )	COM="apt-cache showpkg"
				;;
		c* | C* )	COM="apt-cache rdepends --installed"
				;;
		d* | D* )	COM="aptitude -v --show-summary=all-packages why"
				;;
		e* | E* )	COM="aptitude -s purge"
				;;
		f* | F* )	COM="apt-rdepends -r"
				;;
		* )		COM=""
				echo "\n\t\t ERROR:  Invalid probing choice ..." ;;
	esac

	if [ -n "${COM}" ]
	then
		echo "\n\t Enter package name => \c"

		while read packageNameNoVersNoArch
		do

			if [ -z "${packageNameNoVersNoArch}" ]
			then
				echo "\n\t\t Returning to probe style menu ...\n"
				break
			fi

			rm -f ${TMP}

			echo "\n ----------          ----------          ----------          ----------          ----------          ----------\n"
			ls ${packageNameNoVersNoArch}* >${TMP}

			if [ -s ${TMP} ]
			then

				while read line
				do
					echo "\n #################################################################################"
					echo " PACKAGE:  ${line}\n"

					packBaseName=`echo ${line} | cut -f1 -d_ `

					${COM} ${packBaseName}				
				done <${TMP}
			else
				echo "\n Did not locate package file(s) for ${packageNameNoVersNoArch} ..."
			fi

			echo "\n\t Enter package name => \c"
		done
	fi

	probingMenu
done

exit 0
exit 0
exit 0


#######################################################################################################
#######################################################################################################
#######################################################################################################

root@OasisMega1:/var/cache/apt/archives# 
E: No packages found
root@OasisMega1:/var/cache/apt/archives# aptitude why linux-libc-dev_4.15.0-51.55_amd64.deb

Command 'aptitude' not found, but can be installed with:

apt install aptitude

root@OasisMega1:/var/cache/apt/archives# aptitude why linux-libc-dev_4.15.0-51.55_amd64.deb
E: No package named "linux-libc-dev_4.15.0-51.55_amd64.deb" exists.
root@OasisMega1:/var/cache/apt/archives# ls -l linux-libc-dev*
-rw-r--r-- 1 root root 1004972 May 16 08:03 linux-libc-dev_4.15.0-51.55_amd64.deb
root@OasisMega1:/var/cache/apt/archives# ls -l libqt5sql5-sqlite*
ls: cannot access 'libqt5sql5-sqlite*': No such file or directory
root@OasisMega1:/var/cache/apt/archives# apt-cache showpkg linux-libc-dev


