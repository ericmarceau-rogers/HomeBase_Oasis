#!/bin/sh

if [ "$1" != "--force" ]
then
	echo "\n\t Must use the "--force" option if you intend to convert ALL *.ppm files in the current directory into *.jpeg files.\n" ; exit 1
fi

ls		|
grep '\.ppm$'	|
while read line
do
	echo ""
	file=`basename "${line}" ".ppm" `
	ppmtojpeg --quality=96 "${line}" > "${file}.jpeg"
	ls -l "${file}.jpeg"
done
