#!/bin/sh

if [ "$1" != "--force" ]
then  
	echo "\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	echo   "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n"
	echo   "\n         DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER\n"
	echo   "\n         DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER\n"
	echo "\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	echo   "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n"
	echo "\n\t Please review script for actions before proceeding.\n Bye!\n"
	exit 1
fi

#dd if=/dev/zero of=/dev/sde bs=2048 count=2048

#dd if=/dev/sde of=./flashdrive.img conv=noerror,sync 2>flashdrive.err

### ddrescue /dev/sde ./flashdrive.img ./flashdrive.mapfile 2>flashdrive.err
### ls -l flashdrive.*
### exit 0

###################################################################################################################
###################################################################################################################
###	This information was gleaned from online sources as follows:
###
###	Provided initial overview of sequence but did not provide end-to-end clarity
###	https://cstan.io/?p=8878&lang=en
###
###	List of passwords for various Disk Drive Manufacturers
###	https://web.archive.org/web/20150203193528/https://geekscrowd.wordpress.com/2012/07/31/how-to-remove-password-from-your-hard-disk/
###	https://ipv5.wordpress.com/2008/04/14/list-of-hard-disk-ata-master-passwords/		# original or duplicate ???
###
###	Removing PASSWORD from firmware:
###	https://web.archive.org/web/20150203193528/https://geekscrowd.wordpress.com/2012/07/31/how-to-remove-password-from-your-hard-disk/
###
###	Process for unlocking low-level formatting on drive:
###	https://grok.lsu.edu/Article.aspx?articleid=16716
###
###	Process for unlocking low-level formatting on drive (another):
###	https://wiki.archlinux.org/index.php/Solid_state_drive/Memory_cell_clearing
###
###	Info about MBR wiping, clearing, backup and recovery:
###	https://askubuntu.com/questions/253096/low-level-format-of-hard-drive
###
###	Info about MBR recovery for corrupted systems:
###	https://www.linuxjournal.com/article/10385
###
###
###
###	IMPORTANT:  Clarification on Enhanced Security Erase:
###	https://security.stackexchange.com/questions/62253/what-is-the-difference-between-ata-secure-erase-and-security-erase-how-can-i-en
###
###	Security Erase for SSD (issues from Manufacturer to Manufacturer):
###	https://security.stackexchange.com/questions/41676/ata-security-erase-on-ssd?lq=1
###
###	Overwriting with randomized bits to ensure non-recoverable:
###	https://linux.m2osw.com/low-level-formatting-hard-drives
###
###	Disk Sector Reallocation Statistics (pending failure):
###	http://www.sj-vs.net/forcing-a-hard-disk-to-reallocate-bad-sectors/
###
###
###
###################################################################################################################
###################################################################################################################


TMP=/tmp/`basename "$0" ".sh" `.nonMounted
rm -f ${TMP}*
#BlockDev=""

selectNonMountedDevice_inxi()
{
	command=`which inxi`
	if [ -z "${command}" ]
	then
		echo "\n\t Unable to locate command 'inxi'.  Process abandonned on improper environment for task. \n Bye!\n" ; exit 1
	fi
	echo "\n LOCATED: ${command} ..." ; sleep 5

	inxi -o | sed 's+Unmounted\:++' | cut -f2- -d\- | awk '{ if( NF >0 ) printf("ID-%s\n", $0 ) }' > ${TMP}

	if [ ! -s ${TMP} ]
	then
		echo "\n\t ALL physical disks are currently in use.  No action possible/necessary. \n Bye!\n" ; exit 1
	fi

	for drive in `cat ${TMP} | cut -f2 -d\: | awk '{ if( $2 != "" ) print $2 }' | cut -c1-8 | sort | uniq `
	do
		dataline=`grep ${drive} ${TMP} `
		clear
		echo "\n Disk info for '${drive}':\n\n${dataline} \n\n Repair this disk ? [y|N] => \c"
		read sel
		if [ -z "${sel}" ] ; then  sel="N" ; fi

		case "${sel}" in
			y* | Y* )
				BlockDev="${drive}"
				break
				;;
			* )	;;
		esac
	done

}	#selectNonMountedDevice_inxi()

#selectNonMountedDevice_inxi

selectNonMountedDevice_lsblk()
{
	command=`which lsblk`
	if [ -z "${command}" ]
	then
		echo "\n\t Unable to locate command 'lsblk'.  Process abandonned on improper environment for task. \n Bye!\n" ; exit 1
	fi
	echo "\n LOCATED: ${command} ..." ; sleep 5

#NAME  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
#loop0   7:0    0  55.4M  1 loop /snap/core18/1932
#sda     8:0    0 111.8G  0 disk
#sda1    8:1    0     2G  0 part
#sda2    8:2    0 109.8G  0 part
#sdb     8:16   0   1.8T  0 disk
#sdb1    8:17   0     1G  0 part
#sdb2    8:18   0     7G  0 part [SWAP]
#sdb3    8:19   0 195.3G  0 part /
#sdb4    8:20   0  93.6G  0 part /DB001_F8
#sdb7    8:23   0   293G  0 part /DB001_F2
#sdb8    8:24   0   293G  0 part /DB001_F3
#sdb9    8:25   0   293G  0 part /DB001_F4
#sdb10   8:26   0 996.2M  0 part [SWAP]
#sdb11   8:27   0 996.2M  0 part [SWAP]
#sdb12   8:28   0 195.3G  0 part /DB001_F5
#sdb13   8:29   0 195.3G  0 part /DB001_F6
#sdb14   8:30   0   293G  0 part /DB001_F7
#sdc     8:32   0 465.8G  0 disk
#sdc1    8:33   0     2G  0 part
#sdc2    8:34   0 463.8G  0 part
#sdd     8:48   0 149.1G  0 disk
#sr0    11:0    1  1024M  0 rom

	#lsblk | awk '{ if( $1 ~ /^sd*/ ){ print $1 ; } ; }' | sed 's+Unmounted\:++' | cut -f2- -d\- | awk '{ if( NF >0 ) printf("ID-%s\n", $0 ) }' > ${TMP}
	lsblk --list | awk '{ if( $1 ~ /^sd[a-z]*/ ){ print $1 ; } ; }' >${TMP}.blockdevs
	cat ${TMP}.blockdevs | cut -c1-3 | sort -r | uniq >${TMP}.physical
	while read blockdev
	do
		if [ -z "${blockdev}" ] ; then break ; fi

		length=`echo "${blockdev}" | awk '{ print length($0) }' `
		case ${length} in
			3 ) ;;
			* )
				testor1=`df | grep '^/dev/'${blockdev} `
				testor2=`swapon | grep "/dev/${blockdev}" `
				if [ -n "${testor1}" ]
				then
					echo "${testor1}" | awk '{ printf("BUSY [data]: %s\n", $0 ) ; }'
				else
					if [ -n "${testor2}" ]
					then
						echo "${testor2}" | awk '{ printf("BUSY [swap]: %s\n", $0 ) ; }'
					fi
				fi
				;;
		esac
	done <${TMP}.blockdevs >${TMP}.busy

	OFFLINE=""
	while read physical
	do
		if [ -z "${physical}" ] ; then break ; fi

		testor3=`grep ${physical} ${TMP}.busy `
		if [ -n "${testor3}" ]
		then
			echo "${testor3}" | awk '{ printf("\t || %s\n", $0 ) ; }' >&2
		else
			echo "${physical}"
		fi
	done <${TMP}.physical >${TMP}.offline

	echo ""

	cat ${TMP}.offline | awk '{ if( NF == 1 ){ printf("/dev/%s\n", $0 ) ; } ; }' | sort | tee ${TMP}.z | awk '{ printf("\t || OFFLINE: %s\n", $1 ) ; }' ; mv ${TMP}.z ${TMP}.offline

	if [ ! -s ${TMP}.offline ]
	then
		echo "\n\t ALL physical disks are currently in use.  No action possible/necessary. \n Bye!\n" ; exit 1
	fi

	echo "\n\t Hit return to continue with next step ..." ; read doContinue

	#lsblk -l -p -o NAME,FSTYPE,PARTLABEL,UUID,SIZE,MOUNTPOINT,SUBSYSTEMS | grep -v 'GRUB' | awk  '/[/]dev[/]sd[a-z][0-9]/ { print $0 }' | sort --key=3 > ${TMP}.lsblk
	lsblk -l -p -o NAME,FSTYPE,PARTLABEL,UUID,SIZE,MOUNTPOINT,SUBSYSTEMS | grep -v 'GRUB' | awk  '/[/]dev[/]sd[a-z]/ { if( length($1) == 8 ){ printf("%-12s %10s    %s\n", $1, $2, $3 ) ; } ; }' > ${TMP}.lsblk

	for drive in `cat ${TMP}.offline `
	do
		dataline=`grep ${drive} ${TMP}.lsblk `
		clear
		echo "\n Disk info for '${drive}':\n\n${dataline} \n\n Repair this disk ? [y|N] => \c"
		read sel
		if [ -z "${sel}" ] ; then  sel="N" ; fi

		case "${sel}" in
			y* | Y* )
				BlockDev="${drive}"
				break
				;;
			* )	;;
		esac
	done

}	#selectNonMountedDevice_lsblk()

selectNonMountedDevice_lsblk

if [ -z "${BlockDev}" ]
then
	echo "\n\t No drive selected.  Abandoning process.\n Bye!\n" ; exit 0 
fi

#echo "\n\t IMPORTANT:  need to re-code to ensure prompt for go/no-go at each command to ensure NO accidental destruction of partitions.\n" ; exit 1

echo "\n\t BlockDev= '${BlockDev}' ..."

echo "\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo   "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n"
echo   "\n         DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER\n"
echo   "\n         DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER    DANGER\n"
echo "\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo   "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n"
echo "\n\n\t\t  ARE YOU   >> SURE <<   YOU WANT TO PROCEED ? [y|N] => \c" ; read goAhead

if [ -z "${goAhead}" ]
then
	goAhead="N"
fi
case ${goAhead} in
	y ) ;;
	* ) echo "\n\t Abandonning process.\n Bye!\n" ; exit 1 ;;
esac

echo "\n Proceeding with security erase on ${BlockDev} ...\n"


#FUTURES:  Table for lookup of password based on device manufacturer
#Currently:	All hard drives from single manufacturer, Western Digital.
Password="WDCWDCWDCWDCWDCWDCWDCWDCWDCWDCW"

echo "\n\t Use Manufacturer security password for device ? [y|N] => \c"
read doPass
if [ -z "${doPass}" ] ; then  doPass="N" ; fi

case ${doPass} in
	y* | Y* ) ;;
	* )	Password="" ; echo "\n\t Password for device will not be used ..." ;;
esac

root=`df / | grep '/dev/sd' | awk '{ print $1 }' `

if [ "${BlockDev}" = "${root}" ]
then
	echo "\n\t Unable to proceed.  \n\t Device specified is current root disk.  \n\t Update the script with the intended non-root disk.\n" ; exit 1
fi

Grouping1()
{
smartctl -a ${BlockDev} | grep -i reallocated
sleep 10

echo "\t Hit return to continue => \c" ; read waitForInput

###################
###	STEP I 
###################
echo "\n\n\n** STEP I **  -  Attempting to 'un-freeze' drive ..."

while [ true ]
do
	echo "\n Computer will go to into 'suspend' (or sleep state) in\n\n\t\t  >> 15 sec << \n\n AFTER suspension, simply hit the return key to wake it up again ..."
	sleep 15

	###	Following line commented due to unexplainable non-responsiveness following previous multiple uses where was responsive !!!
	#echo -n mem > /sys/power/state

	hdparm -I ${BlockDev} >${TMP}.2 2>&1
	cat ${TMP}.2

	enhErase=`grep 'supported: enhanced erase' ${TMP}.2 | grep -v 'not' `
	if [ -n "${enhErase}" ]
	then
		echo "\n\t Option 'security-erase-enhanced'  IS  supported ..."
	else
		echo "\n\t Option 'security-erase-enhanced'  IS NOT  supported ..."
	fi

	echo "\n\n The above should show as per below (otherwise repeat above cycle until this appears):\n"
	echo "
	Security:
		Master password revision code = 65534
			supported
		not	enabled
		not	locked
		not	frozen				# <<<<<< We want to see this condition reported
		not	expired: security count
			supported: enhanced erase
		74min for SECURITY ERASE UNIT. 74min for ENHANCED SECURITY ERASE UNIT.
	Logical Unit WWN Device Identifier: 50014ee0018be658
	"

	echo "\n OK to proceed with next step ? (empty response will repeat) [y|N] => \c"
	read g

	if [ -z "$g" ] ; then  g="N" ; fi

	case ${g} in
		y* | Y* )	echo "\n\t Moving on ..."
				break
			;;
		* )	
			echo "\n\n\n** STEP I **  -  Attempting to 'un-freeze' drive  [ REPEATED ] ..."
			;;
	esac
done

echo "\n Hit return to continue ..." ; read k


if [ -n "${Password}" ]
then
	###################
	###	STEP II 
	###################

	echo "\n\n\n** STEP II **  -  set security password to protect the hard drive ..."

	## This step is intended for increasing boot-time access security; not required for drive out-of-box; 
	#	hdparm --user-master u --security-set-pass ${Password} ${BlockDev}
	echo " => hdparm --user-master u --security-set-pass ${Password} ${BlockDev} ..."
	echo "\t START = `date` ..."
	hdparm --user-master u --security-set-pass ${Password} ${BlockDev}
	echo "\t END   = `date`"

	hdparm -I ${BlockDev}

	echo "\n Hit return to continue ..." ; read k
fi


if [ -n "${Password}" ]
then
	###################
	###	STEP III (if necessary)
	###################
	
	dskLock=`grep 'locked' ${TMP}.2 | grep -v 'not' `

	if [ -n "${dskLock}" ]
	then
		echo "\n\t WARNING:  disk is locked by manufacturer.\n"

		echo "\n\n\n** STEP III **  -  attempting to un-lock security on disk ..."

		echo " => hdparm --user-master m --security-unlock ${Password} ${BlockDev} ..."
		echo "\t START = `date` ..."
		hdparm --user-master m --security-unlock ${Password} ${BlockDev}
		echo "\t END   = `date`"

		hdparm -I ${BlockDev}

		echo "\n Hit return to continue ..." ; read k
	else
		echo "\n\t NOTE:  disk is NOT locked by manufacturer.\n"
	fi
fi


###################
###	STEP IV 
###################
	
doSecurityErase()
{
	testor=`smartctl -a /dev/sdd | grep 'for SECURITY ERASE' | head -1 `

	if [ -n "${testor}" ]
	then
		echo "\n ESTIMATED time for action:  ${testor} ..."
	else
		echo "\n ESTIMATED time for action:  `smartctl -a /dev/sdd | grep 'polling time' | sort -nr --key=5 | head -1 ` ..."
	fi

	if [ -n "${enhErase}" ]
	then
		echo "\n\n\n** STEP IV **  -  attempting 'security-erase-enhanced' ..."

		echo " => hdparm --user-master u --security-erase-enhanced ${Password} ${BlockDev} ..."
		echo "\t START = `date` ..."
		hdparm --user-master u --security-erase-enhanced ${Password} ${BlockDev}
		echo "\t END   = `date`"
	else
		echo "\n\n\n** STEP IV **  -  attempting 'security-erase' ..."

		echo " => hdparm --user-master u --security-erase ${Password} ${BlockDev} ..."
		echo "\t START = `date` ..."
		hdparm --user-master u --security-erase ${Password} ${BlockDev}
		echo "\t END   = `date`"
	fi
}

if [ -n "${Password}" ]
then
	doSecurityErase
else
	## FUTURES:  does the command line need to remove reference to --user-master ???

	doSecurityErase
fi

hdparm -I ${BlockDev}

echo "\n Hit return to continue ..." ; read k


## NOTE:  disable password function with following:  
echo "\n\t Following is required to purge the password setting if the 'secure-erase' operation failed.\n"
echo " => hdparm --user-master u ---security-disable ${Password} ${BlockDev} ..."
hdparm --user-master u ---security-disable ${Password} ${BlockDev}

hdparm -I ${BlockDev}

}	#Grouping1()


Grouping1		## This grouping uses factory built-in functions at multiple steps to erase disk contents.

echo "\n\n Abandonned at specified exit point.\n" 

exit 0
exit 0
exit 0


Grouping2()
{

###################
###	STEP VI 
###################
	
echo "\n\n\n** STEP VI **"

echo "\n\t Do you want to destroy any data bits by overwriting with randomized bits ? [y/N] => \c"
read k

if [ -z "$k" ] ; then  k="N" ; fi

case ${k} in
	y* | Y* )	sleep 20
			rm -f ${TMP}
			fdisk -l ${BlockDev} >${TMP}
			DevByteCount=`head -1 ${TMP} | awk '{ print $5 }' `

			#Disk /dev/sdc: 465.8 GiB, 500107862016 bytes, 976773168 sectors
			#Units: sectors of 1 * 512 = 512 bytes
			#Sector size (logical/physical): 512 bytes / 512 bytes
			#I/O size (minimum/optimal): 512 bytes / 512 bytes
			#Disklabel type: dos
			#Disk identifier: 0x1c85d85c
			#
			#Device     Boot   Start       End   Sectors   Size Id Type
			#/dev/sdc1          2048   8390655   8388608     4G 82 Linux swap / Solaris
			#/dev/sdc2  *    8390656 976773119 968382464 461.8G 83 Linux
			echo "\n\t Current 'fdisk' report for device ${BlockDev} (${DevByteCount} bytes to be randomized):\n"
			cat ${TMP}

			echo "\n\t You are sure you want to destroy any remaining data impression on ${BlockDev} ? [y/N] => \c"
			read z

			if [ -z "$z" ] ; then  z="N" ; fi

			case ${z} in
				y* | Y* )	#cat /dev/urandom >${BlockDev}
						dd status=progress count=${DevByteCount} if=/dev/urandom of=${BlockDev}
					;;
				* )	;;
			esac
		;;
	* )	;;
esac


}	#Grouping2()


#Grouping2		### This grouping is to perform paranoia-driven data obliteration by overwriting disk contents randomly.



###################
###	STEP VII 
###################
	
echo "\n\n\n** STEP VII **"

echo "\n\t Is installation of grub in MBR required ? [y/N] => \c"
read k

if [ -z "$k" ] ; then  k="N" ; fi

case ${k} in
	y* | Y* )	grub-install --no-floppy ${BlockDev}
		;;
	* )	;;
esac


exit 0
exit 0
exit 0


Info()
{
================================================================================================
BEFORE Step I (report - Before UN-freeze)

Security:
	Master password revision code = 65534
		supported
	not	enabled
	not	locked
		frozen					# <<<<< ISSUE IS THIS
	not	expired: security count
		supported: enhanced erase
	74min for SECURITY ERASE UNIT. 74min for ENHANCED SECURITY ERASE UNIT.
Logical Unit WWN Device Identifier: 50014ee0018be658


================================================================================================
BEFORE Step II (report - Before Password set)

Security:
	Master password revision code = 65534
		supported
	not	enabled					# <<<<< ISSUE IS NOW THIS
	not	locked
	not	frozen					# <<<<< Updated as required
	not	expired: security count
		supported: enhanced erase
	74min for SECURITY ERASE UNIT. 74min for ENHANCED SECURITY ERASE UNIT.
Logical Unit WWN Device Identifier: 50014ee0018be658


================================================================================================
BEFORE Step IV (report - Before Secure Erase operation)

Security: 
	Master password revision code = 65534
		supported
		enabled					# <<<<< Updated as required
	not	locked
	not	frozen
	not	expired: security count
		supported: enhanced erase
	Security level high				# <<<<< Confirms password is set
	74min for SECURITY ERASE UNIT. 74min for ENHANCED SECURITY ERASE UNIT.
Logical Unit WWN Device Identifier: 50014ee0018be658


================================================================================================
AFTER  Step V (report - AFTER Enhanced Secure Erase operation)

ATA device, with non-removable media
	Model Number:       WDC WD5000AAKS-00V1A0
	Serial Number:      WD-WMAWF0060756
	Firmware Revision:  05.01D05
	Transport:          Serial, SATA 1.0a, SATA II Extensions, SATA Rev 2.5, SATA Rev 2.6
Standards:
	Supported: 8 7 6 5
	Likely used: 8
Configuration:
	Logical		max	current
	cylinders	16383	16383
	heads		16	16
	sectors/track	63	63
	--
	CHS current addressable sectors:    16514064
	LBA    user addressable sectors:   268435455
	LBA48  user addressable sectors:   976773168
	Logical/Physical Sector size:           512 bytes
	device size with M = 1024*1024:      476940 MBytes
	device size with M = 1000*1000:      500107 MBytes (500 GB)
	cache/buffer size  = 16384 KBytes
Capabilities:
	LBA, IORDY(can be disabled)
	Queue depth: 32
	Standby timer values: spec d by Standard, with device specific minimum
	R/W multiple sector transfer: Max = 16	Current = 0
	Recommended acoustic management value: 128, current value: 254
	DMA: mdma0 mdma1 mdma2 udma0 udma1 udma2 udma3 udma4 udma5 *udma6
	     Cycle time: min=120ns recommended=120ns
	PIO: pio0 pio1 pio2 pio3 pio4
	     Cycle time: no flow control=120ns  IORDY flow control=120ns
Commands/features:
	Enabled	Supported:
	   *	SMART feature set
	    	Security Mode feature set
	   *	Power Management feature set
	   *	Write cache
	   *	Look-ahead
	   *	Host Protected Area feature set
	   *	WRITE_BUFFER command
	   *	READ_BUFFER command
	   *	NOP cmd
	   *	DOWNLOAD_MICROCODE
	    	Power-Up In Standby feature set
	   *	SET_FEATURES required to spinup after power up
	    	SET_MAX security extension
	   *	Automatic Acoustic Management feature set
	   *	48-bit Address feature set
	   *	Device Configuration Overlay feature set
	   *	Mandatory FLUSH_CACHE
	   *	FLUSH_CACHE_EXT
	   *	SMART error logging
	   *	SMART self-test
	   *	General Purpose Logging feature set
	   *	64-bit World wide name
	   *	{READ,WRITE}_DMA_EXT_GPL commands
	   *	Segmented DOWNLOAD_MICROCODE
	   *	Gen1 signaling speed (1.5Gb/s)
	   *	Native Command Queueing (NCQ)
	   *	Host-initiated interface power management
	   *	Phy event counters
	   *	NCQ priority information
	   *	DMA Setup Auto-Activate optimization
	   *	Software settings preservation
	   *	SMART Command Transport (SCT) feature set
	   *	SCT Read/Write Long (AC1), obsolete
	   *	SCT Write Same (AC2)
	   *	SCT Error Recovery Control (AC3)
	   *	SCT Features Control (AC4)
	   *	SCT Data Tables (AC5)
	    	unknown 206[12] (vendor specific)
	    	unknown 206[13] (vendor specific)
Security:
	Master password revision code = 65534
		supported
	not	enabled
	not	locked
	not	frozen
	not	expired: security count
		supported: enhanced erase
***	Security level high				# <<<<< This line should be GONE !!!  ==>> password is removed.
	74min for SECURITY ERASE UNIT. 74min for ENHANCED SECURITY ERASE UNIT.
Logical Unit WWN Device Identifier: 50014ee0018be658
	NAA		: 5
	IEEE OUI	: 0014ee
	Unique ID	: 0018be658
Checksum: correct

================================================================================================

}



