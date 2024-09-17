#!/bin/sh

if [ "$1" != "--force" ]
then
	echo "\n\t Must use the "--force" option if you intend to convert ALL *.webp files in the current directory into *.ppm files.\n" ; exit 1
fi

ls		|
grep '\.webp$'	|
while read line
do
	echo ""
	file=`basename "${line}" ".webp" `
	dwebp "${line}" -ppm -o "${file}.ppm"
	ls -l "${file}.ppm"
done
