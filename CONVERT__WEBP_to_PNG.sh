#!/bin/sh

if [ "$1" != "--force" ]
then
	echo "\n\t Must use the "--force" option if you intend to convert ALL *.webp files in the current directory into *.png files.\n" ; exit 1
fi

ls		|
grep '\.webp$'	|
while read line
do
	echo ""
	file=`basename "${line}" ".webp" `
	dwebp "${line}" -o "${file}.png"
	ls -l "${file}.png"
done
