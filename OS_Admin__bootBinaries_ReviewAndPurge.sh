#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: OS_Admin__bootBinaries_ReviewAndPurge.sh,v 1.1 2020/09/17 03:11:42 root Exp root $
###
###	Script to identify OS build versions that are installed and purge all except the last 2.
###
####################################################################################################

#DevStat=PROD
TMP=/tmp/tmp.`basename $0 ".sh"`.$$

VERSIONS=0
LATEST=0

sync
testor1="`ps -ef | grep -v 'grep' | grep 'synaptic' | head -1 `"
testor2="`ps -ef | grep -v 'grep' | grep 'dpkg' | head -1 `"
testor3="`ps -ef | grep -v 'grep' | grep 'apt' | head -1 `"

if [ -n "${testor1}" ]
then
	echo "\n Active processes identified:\n\t ${testor1}"
	echo "\n This process may not continue until 'synaptic' is shut down.\n"
	exit 1
else
	if [ -n "${testor2}" ]
	then
		echo "\n Active processes identified:\n\t ${testor2}"
		echo "\n This process may not continue until 'dpkg*' is shut down.\n"
		exit 1
	else
		if [ -n "${testor3}" ]
		then
			echo "\n Active processes identified:\n\t ${testor2}"
			echo "\n This process may not continue until 'apt*' is shut down.\n"
			exit 1
		fi
	fi
fi

echo "\n\t This script identifies build versions that are installed, \n\t does not touch 2 most recent versions, and offers \n\t the remaining list of older builds for selective \n\t direct purge, not an uninstall process ...\n"

#FUTURES:  add logic to do uninstall of items that are chosen for purge.


#/boot/abi-3.13.0-143-generic
#/boot/config-3.13.0-143-generic
#/boot/initrd.img-3.13.0-143-generic
#/boot/retpoline-3.13.0-143-generic
#/boot/System.map-3.13.0-143-generic
#/boot/vmlinuz-3.13.0-143-generic

cd /boot
mode=generic

echo "\n\t Bootable versions ..."
#ls -l vmlinuz* | sort -r --version-sort | awk '{ printf("\t\t%s\n",$0) }'
ls -lt vmlinuz* | awk '{ printf("\t\t %s\n",$0) }'

sleep 4

echo""
for pref in  vmlinuz System.map retpoline initrd.img config abi
do
	echo "\t Getting versions of  '${pref} ..."
	rm -f ${TMP}.${pref}.v

	( ls ${pref}-*-${mode} | sort -n >${TMP}.${pref}.all ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
	#cat ${TMP}.${pref}.all | cut -f2-3 -d\- | sort -nr --version-sort >${TMP}.${pref}.v
	cat ${TMP}.${pref}.all | cut -f2-3 -d\- | sort -nr --key=2.1,3.0 --field-separator="-" >${TMP}.${pref}.v
done

echo""
for pref in  System.map retpoline initrd.img config abi
do
	echo "\n\t Looking for differences in versions of  '${pref} ..."
	diff ${TMP}.vmlinuz.v ${TMP}.${pref}.v >${TMP}.${pref}.diff

	if [ -s ${TMP}.${pref}.diff ]
	then
	{
		echo " === ${TMP}.${pref}.diff "
		cat ${TMP}.${pref}.diff
	} | awk '{ printf("\t\t %s\n", $0 ) }'
	else
		echo "\t\t Versions match up ... "
	fi
done

#echo here
#cat ${TMP}.vmlinuz.v
#echo there

purgePackageName()
{
	rm -f ${TMP}.purge ${TMP}.RC

	echo "\t\t Purging: ${pkgName} ...\c"
	( dpkg --purge ${pkgName} 2>&1 ; RC=$? ; echo "${RC}" >${TMP}.RC ) >${TMP}.purge

	read RC <${TMP}.RC

	#testor=`grep 'error' ${TMP}.err 2>/dev/null`

	#if [ \( ${RC} -ne 0 \) -o \( -n "${testor}" \) ]
	if [ ${RC} -ne 0 ]
	then
		#echo "\n\t\t Log of attempt [${pkgName}]:"
		echo " FAILED!"
		cat ${TMP}.purge | awk '{ printf("\t\t\t %s\n",$0) }'
		echo "\n\t\t Encountered error during purging attempt.  Abandoning job until issue is resolved.\n" ; exit 1
	else
		#echo " SUCCESS!"
		echo ""
	#	if [ -s ${TMP}.purge ]
	#	then
	#		echo "\n\t\t Log of purge:"
	#		cat ${TMP}.purge | awk '{ printf("\t\t\t %s\n",$0) }'
	#	fi
	fi
}	#purgePackageName()

verifyVersionPurge()
{
	echo "\n\t Verifying PURGE action .."

	partialPurge=0
	for pkgName in `cat ${TMP}.thisVersion `
	do
		#echo "\n [VERIFY] pkgName= ${pkgName}"
		rm -f ${TMP}.RC

		( dpkg -l ${pkgName} ; RC=$? ; echo "${RC}" >${TMP}.RC ) 2>&1 | grep ${pkgName} >>/dev/null

		read RC <${TMP}.RC

		if [ ${RC} -eq 0 ]
		then
			echo "\t\t Purge of ${pkgName} FAILED or SKIPPED ..."
			partialPurge=1
		else
			echo "\t\t PURGED: ${pkgName} ..."
		fi
	done

	if [ ${partialPurge} -eq 0 ]
	then
		echo "\n\t Version ${version} package grouping PURGED.  Doing sanity check ..."

		find / -xdev -print >z ; grep "${version}" z | sort >${admin}/OS_KernelPurge_${version}.list
		if [ -s "${admin}/OS_KernelPurge_${version}.list" ]
		then
			echo "\n\t WARNING:  Verify listing in '${admin}/OS_KernelPurge_${version}.list' for possible leftovers from purge .."
		else
			echo "\t\t Sanity check identified no overlooked items ..."
		fi
	else
		echo "\n\t WARNING:  PARTIAL purge of version ${version} package grouping ..."
	fi
}	#verifyVersionPurge()

if [ -n "`tail -n +3 ${TMP}.vmlinuz.v`" ]
then
	tail -n +3 ${TMP}.vmlinuz.v | sort |
	while read version
	do
		echo "\n\n Boot-related files for ${version} KERNEL:\n"
		ls -l *-${version}-${mode} 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'

		echo "\n\n Packages related to ${version} KERNEL:\n"

		rm -f ${TMP}.thisVersion*
		dpkg -l | grep "${version}" | awk '{ print $2 }' | grep '^linux-' | sort -r >${TMP}.thisVersion.tmp
		{
			grep 'linux-headers-' ${TMP}.thisVersion.tmp
			grep 'linux-hwe-' ${TMP}.thisVersion.tmp | grep 'headers-'
			grep 'linux-modules-extra-' ${TMP}.thisVersion.tmp
			grep 'linux-image-' ${TMP}.thisVersion.tmp
			grep 'linux-modules-' ${TMP}.thisVersion.tmp | grep -v 'modules-extra'
		} >${TMP}.thisVersion

		cat ${TMP}.thisVersion | awk '{ printf("\t\t %s\n",$0) }'

		echo "\n\t Purge all packages for this version ? [y|N] => \c"
		read ans <&2
	
		case "$ans" in
			y* | Y* )
				#echo "\n\t Removing files for version ${version} ..."
				#for pref in vmlinuz System.map retpoline initrd.img config abi
				#do
				#	ls -l ${pref}-${version}-${mode} 2>&1
				#	rm -fv ${pref}-${version}-${mode} 
				#done | awk '{ printf("\t\t %s\n",$0) }'
				echo "\n\t\t ARE YOU SURE YOU WANT TO DO THAT ? [y|N] => \c"
				read vans <&2

				case "${vans}" in
					y* | Y* )
						echo "\n\t Purging packages for version ${version} ...\n"

						for pkgName in `cat ${TMP}.thisVersion `
						do
							purgePackageName
						done

						verifyVersionPurge
						;;
					* )
						echo "\t Leaving version ${version} untouched ..."
						;;
				esac
				;;
			* )
				echo "\n Purge any of those ${version} packages ? [y|N] => \c"
				read nans <&2

				case "${nans}" in
					y* | Y* )
						for pkgName in `cat ${TMP}.thisVersion `
						do
							echo "\t Purge  ${pkgName} ? [y|N] => \c"
							read mans <&2

							case "${mans}" in
								y* | Y* )
									purgePackageName
									;;
								* )
									echo "\t\t Leaving ${pkgName}  untouched ..."
									;;
							esac
						done

						verifyVersionPurge
						;;
					* )
						echo "\n\t Leaving version ${version} untouched ..."
						;;
				esac
				;;
		esac

		echo "\n\n\t\t#############################################\n\n"
	done
else
	echo "\n\t Only 2 bootable KERNEL versions remaining as desired."
fi

echo "\n\t Remaining bootable KERNEL versions:"
#ls -l vmlinuz* | sort -r --version-sort | awk '{ printf("\t\t%s\n",$0) }'
ls -lt vmlinuz* 2>&1 | awk '{ printf("\t\t %s\n",$0) }'
echo "\n Bye!\n"


exit 0
exit 0
exit 0


