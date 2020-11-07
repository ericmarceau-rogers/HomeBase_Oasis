#!/bin/sh

###	$Id: $
###	Script to provide low-level report on partition allocation details on drives.

BASE=/tmp/`basename $0 ".sh"`
TMP=${BASE}.tmp

parted -l >${TMP}
cat ${TMP}
exit

while read line
do
	case "${line}" in
		Model* )
			# Model: ATA WDC WD1200JB-00G (scsi)
			testOR=`echo "${line}" | cut -f2 -d\:`

			if [ -n "${testOR}" ]
			then
				#echo ${testOR}
				MODEL="${testOR}"
			fi
			;;
		Partition* )
			# Partition Table: msdos
			# Partition Table: gpt
			testOR=`echo "${line}" | cut -f2 -d\: | awk '{ print $1 }'`		

			#echo ${testOR}
			TABLE="${testOR}"
			;;
		Disk* )
			# Disk /dev/sda: 120GB
			testOR=`echo "${line}" | grep '/dev' | cut -f1 -d\: | awk '{ print $2 }'`		

			if [ -n "${testOR}" ]
			then
				#echo ${testOR}
				DISK="${testOR}"
			fi
			;;
		Number* )
			while read line
			do
				if [ -n "${line}" ]
				then
					partTYP="`echo $line | grep 'ext' | grep -v 'exten' `"

					if [ -n "${partTYP}" ]
					then
						#echo ${partTYP}
						partNO=`echo "${line}" | awk '{ print $1 }'`
						#echo "${partNO}"

						case ${TABLE} in
							msdos)
								# Number  Start   End    Size    Type      File system     Flags
								#  1      1049kB  116GB  116GB   primary   ext4            boot
								echo "${DISK}${partNO}|`echo "${partTYP}" | awk '{ print $6 }'`|${MODEL}"
								;;
							gpt)
								#Number  Start   End     Size    File system     Name  Flags
								# 1      1049kB  2097kB  1049kB
								# 2      2097kB  315GB   315GB   ext4                  boot, esp
								echo "${DISK}${partNO}|`echo "${partTYP}" | awk '{ print $5 }'`|${MODEL}"
								;;
							* )	echo "\t WARNING:  Unknown partition table type: ${TABLE} !!!\n"
								;;
						esac
					fi
				else
					break
				fi
			done
			;;
	esac
done <${TMP}

exit 0
exit 0
exit 0
