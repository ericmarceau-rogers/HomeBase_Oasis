#!/bin/sh

LOG="DB001_F5.tune2fs_AFTER.txt"

SHOW=0
if [ "$1" = "--showdiff" ]
then
	SHOW=1
fi
### 'tune2fs' does not report as completely as 'dumpe2fs' regarding characteristics.
if [ ${SHOW} -eq 1 ] ; then  tune2fs -l /dev/sda12 >"${LOG}.2" ; fi

dumpe2fs -h /dev/sda12 >"${LOG}"

cat "${LOG}"

if [ ${SHOW} -eq 1 ] ; then
	echo "\ndiff:"
	diff "${LOG}.2" "${LOG}"
fi
