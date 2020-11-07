#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: Devices__ReportDiskParts.sh,v 1.4 2020/11/07 18:52:07 root Exp $
###
###	Script to report all partitions that detected by the system.
###
####################################################################################################

TMP=/tmp/`basename $0 ".sh" `.tmp

doFSTAB=0
while [ $# -gt 0 ]
do
	case $1 in
		"--fstab" )	doFSTAB=1 ; break ;;
		"--disk" )	lsblk -l -p --output-all | awk  '/[/]dev[/]sd[a-z][0-9]/ { print $0 }' | sort --key=3 | awk '{ printf("%s\n\n", $0 ) ; }' ; exit 0 ;;
		"--raw" )	lsblk -l -p --output-all | sort --key=3 | awk '{ printf("%s\n\n", $0 ) ; }' ; exit 0 ;;
		* )  echo "\n\t Invalid parameter '$1' used on command line.  Only options allowed:  [ --raw | --disk | --fstab ]\n Bye!\n" ; exit 1 ;;
	esac
done

if [ -z "${MROOT}" ]
then
	thisUser=`whoami`
	realUser="${SUDO_USER}"

	if [ ${thisUser} = ${realUser} ]
	then
        	loginName=`basename ${HOME} `
	else
        	loginName="${realUser}"
	fi

	thisUser="${loginName}"
	MROOT="/media/${thisUser}" ; export MROOT
fi

pROOT=`df / | grep '/dev/' | awk '{ print $1 }' `
dROOT=`echo ${pROOT} | cut -c1-8 `

# If not terminal redirect comments to stderr.
if [   -t 1 ] ; then echo "\n\t NOTE:  Expected mount point parent for all partitions not on root device => '$MROOT' ..."   ; fi
#if [ ! -t 1 ] ; then echo "\n\t NOTE:  Expected mount point parent for all partitions not on root device => '$MROOT' ..." >&2 ; fi

###
###	All available parameters for lsblk	(based on lsblk from util-linux 2.31.1)
###
###	In sort order reported by --output-all
###
#1	 NAME
#	 KNAME
#	 MAJ:MIN
#2	 FSTYPE
#5	 MOUNTPOINT
#	 LABEL
#4	 UUID
#	 PARTTYPE
#3	 PARTLABEL
#	 PARTUUID
#	 PARTFLAGS
#	 RA
#	 RO
#	 RM
#	 HOTPLUG
#	 MODEL
#	 SERIAL
#6	 SIZE
#	 STATE
#	 OWNER
#	 GROUP
#	 MODE
#	 ALIGNMENT
#	 MIN-IO
#	 OPT-IO
#	 PHY-SEC
#	 LOG-SEC
#	 ROTA
#	 SCHED
#	 RQ-SIZE
#	 TYPE
#	 DISC-ALN
#	 DISC-GRAN
#	 DISC-MAX
#	 DISC-ZERO
#	 WSAME
#	 WWN
#	 RAND
#	 PKNAME
#	 HCTL
#	 TRAN
#	 SUBSYSTEMS
#	 REV
#	 VENDOR
#	 ZONED


#lsblk -l -p -o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT,SIZE | grep '/dev/sd??' 
#lsblk -l -p -o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT,SIZE | awk  '/[/]dev[/]sd[a-z][0-9]/ { print $0 }' | sort --key=3 > ${TMP}.lsblk
lsblk -l -p -o NAME,FSTYPE,PARTLABEL,UUID,SIZE,MOUNTPOINT | grep -v 'GRUB' | awk  '/[/]dev[/]sd[a-z][0-9]/ { print $0 }' | sort --key=3 > ${TMP}.lsblk

## WD 4 TB My Book
#----------------------------------------------------------------------------------------------------------------------
#/dev/sdb1 on /media/ericthered/My Book type exfat (rw,nosuid,nodev,relatime,uid=1000,gid=1000,fmask=0022,dmask=0022,iocharset=utf8,namecase=0,errors=remount-ro,uhelper=udisks2)
###	1,4,9,7,5,18
#----------------------------------------------------------------------------------------------------------------------
###	/dev/sdb1    exfat    My         Book                                   Not_Mounted   /My
#/dev/sdb1  /dev/sdb1  /dev/sdb1    8:17     3.7T   3.7T exfat        6M     0% /media/ericthered/My Book     My Book  40FA-E56B                            fc843c51-1aec-4aab-8676-9043c9e59d0d atari  ebd0a0a2-b9e5-4433-87c0-68b6b72699c7 My Book   4c1ee663-135c-4809-a61e-f38ec52d80a7           128  0  0       1                                                  3.7T         root  disk  brw-rw----         0   4096      0    4096     512    1 mq-deadline       2 part        0        4K       4G         0    0B                       1 /dev/sdb                   block:scsi:usb:pci               none
#----------------------------------------------------------------------------------------------------------------------
###	/dev/sde3    ext4     DB002_F1   1b4157be-79cd-472b-96d9-a4cabacaffe1   Not_Mounted   /media/ericthered/DB002_F1
#/dev/sde3  /dev/sde3  /dev/sde3    8:67                 ext4                                                 DB002_F1 1b4157be-79cd-472b-96d9-a4cabacaffe1 9a3649a5-cbbb-4f1b-ae0b-f3c0d9cdec21 dos    c12a7328-f81f-11d2-ba4b-00a0c93ec93b DB002_F1  a9b2eda8-ec21-4999-b1f6-eab36ce3bf75           128  0  0       0                                                279.4G         root  disk  brw-rw----         0   4096      0    4096     512    1 mq-deadline      64 part        0        0B       0B         0    0B 0x50014ee263b2c636    1 /dev/sde                   block:scsi:pci                   none
#----------------------------------------------------------------------------------------------------------------------




if [ ${doFSTAB} -eq 0 ]
then
	if [   -t 1 ] ; then echo "\n\t ALL recognized DISK partitions:\n"     ; fi
	#if [ ! -t 1 ] ; then echo "\n\t ALL recognized DISK partitions:\n" >&2 ; fi

	cat ${TMP}.lsblk | awk -v othrPath=${MROOT} -v dROOT="${dROOT}" '{
	     if ( ( NF == 6 ) && ( $2 == "swap" ) )	printf("%-12s %-8s %-10s %-38s %-13s %s\n", $1, $2, $3, $4, "Enabled", $6 ) ;
	else if ( ( NF == 6 ) && ( $2 != "swap" ) )	printf("%-12s %-8s %-10s %-38s %-13s %s\n", $1, $2, $3, $4, "Mounted", $6 ) ;
	else if ( ( NF == 5 ) && ( $2 == "swap" ) )	printf("%-12s %-8s %-10s %-38s %-13s %s\n", $1, $2, $3, $4, "Not_Enabled", "[SWAP_OFFLINE]" ) ;  
	else	if ( ( NF == 5 ) && ( $2 != "swap" ) && ( index($1,dROOT) == 0) ){
			printf("%-12s %-8s %-10s %-38s %-13s %s/%s\n", $1, $2, $3, $4, "Not_Mounted", othrPath, $3 ) ; 
		}else{
			printf("%-12s %-8s %-10s %-38s %-13s /%s\n", $1, $2, $3, $4, "Not_Mounted", $3 ) ; 
		} ;
	}'
else
	if [   -t 1 ] ; then echo "\n\t ALL recognized DISK partitions reported in format required to update '/etc/fstab':\n"     ; fi
	#if [ ! -t 1 ] ; then echo "\n\t ALL recognized DISK partitions reported in format required to update '/etc/fstab':\n" >&2 ; fi

	#/dev/sdd1    ext4     DB002_F1   0aa50783-954b-4024-99c0-77a2a54a05c2   300G          /media/ericthered/DB002_F1
	#UUID=f56b6086-229d-4c17-8a5b-e68de1a4e73d	/	ext4	errors=remount-ro	0	1
	#UUID=7e9a663e-ff1d-4730-8544-c37519056b6f	/DB001_F2	ext4	nosuid,nodev,nofail,errors=remount-ro	0	2 
	#UUID=c37e53cd-5882-401c-8ba3-172531a082e9	none	swap	sw,pri=3	0	0

	###
	###	FUTURES:   USB options  rw,suid,umask=0000,uid=1000,gid=1000
	###
	cat ${TMP}.lsblk | awk -v othrPath=${MROOT} -v pROOT="${pROOT}" -v dROOT="${dROOT}" '{
	     if ( ( NF == 6 ) && ( $2 == "swap" ) ){
			printf("# %-12s %-8s %-10s %-38s %-13s %s\n", $1, $2, $3, $4, $5, $6 ) ;
			printf("UUID=%s \t%s \t%s \t%s \t%s \t%s\n\n", $4, "none", $2, "sw,pri=2", "0", "0" ) ;
		} 
	else if ( ( NF == 6 ) && ( $2 != "swap" ) ){
			if ( $1 == pROOT ) {
				perms="defaults" ;
				seq=0 ;
			}else{
				#perms="nosuid,nodev,nofail,defaults" ;
				perms="nofail,defaults" ;
				if ( $1 ~ dROOT ) { seq=2 ; }else{ seq=3 ; } ;
			} ;
			printf("# %-12s %-8s %-10s %-38s %-13s %s\n", $1, $2, $3, $4, $5, $6 ) ;
			printf("UUID=%s \t%s \t%s \t%s \t%s \t%s\n\n", $4, $6, $2, perms, "0", seq ) ;
		} 
	else if ( ( NF == 5 ) && ( $2 == "swap" ) ){
			printf("# %-12s %-8s %-10s %-38s %-13s %s\n", $1, $2, $3, $4, $5, "[SWAP]" ) ;  
			printf("UUID=%s \t%s \t%s \t%s \t%s \t%s\n\n", $4, "none", $2, "sw,pri=2", "0", "0" ) ;
		} 
	else if ( ( NF == 5 ) && ( $2 != "swap" ) ){
			if ( $1 == pROOT ) {
				perms="defaults" ;
				seq=0 ;
			}else{
				#perms="nosuid,nodev,nofail,defaults" ;
				perms="nofail,defaults" ;
				if ( $1 ~ dROOT ) { seq=2 ; }else{ seq=3 ; } ;
			} ;
			#printf("# %-12s %-8s %-10s %-38s %-13s %s/%s\n", $1, $2, $3, $4, $5, othrPath, $3 ) ; 
			#printf("UUID=%s \t%s%s \t%s \t%s \t%s \t%s\n\n", $4, othrPath, $3, $2, perms, "0", seq ) ;
			if ( index($1,dROOT) == 0 ){
				printf("# %-12s %-8s %-10s %-38s %-13s %s/%s\n", $1, $2, $3, $4, $5, othrPath, $3 ) ; 
				printf("UUID=%s \t%s/%s \t%s \t%s \t%s \t%s\n\n", $4, othrPath, $3, $2, perms, "0", seq ) ;
			}else{
				printf("# %-12s %-8s %-10s %-38s %-13s /%s\n", $1, $2, $3, $4, $5, $3 ) ; 
				printf("UUID=%s \t/%s \t%s \t%s \t%s \t%s\n\n", $4, $3, $2, perms, "0", seq ) ;
			} ;
		} ;
	}'
fi

# Other command format for other properties related to partitions:
#	lsblk -o NAME,ALIGNMENT,MIN-IO,OPT-IO,PHY-SEC,LOG-SEC,ROTA,SCHED,RQ-SIZE,RA,WSAME

# Other option which is not as complete:
#	blkid -o list

if [   -t 1 ] ; then echo "\n\t Done.  [`basename $0 `]\n"     ; fi
if [ ! -t 1 ] ; then echo "\t Done.  [`basename $0 `]\n" >&2 ; fi

rm -f ${TMP}.*

exit 0
exit 0
exit 0

