#!/bin/sh

dmesg | egrep -i --color 'cdrom|dvd|cd/rw|writer'

echo "\n ================================================================================================\n"

cat /proc/sys/dev/cdrom/info

echo "\n ================================================================================================\n"

cd-info /dev/sr0
if [ $? -ne 0 ]
then
	iso-info /dev/sr0
fi
