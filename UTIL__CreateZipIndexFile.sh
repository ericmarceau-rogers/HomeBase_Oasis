#!/bin/sh

ZIPFILE="$1"

case "${ZIPFILE}" in
	*.zip ) if [ ! -s "${ZIPFILE}" ] ; then  echo "\n\t Unable to locate file '${ZIPFILE}'.\n Bye!\n" ; exit 1 ; fi ;;
	* ) echo "\n\t This may only be used to create a custom-formatted index file of a specified tar.\n\t The index is reverse alphanum sorted with all directory file references segregated at bottom of the list.\n" ; exit 1 ;;
esac
		

unzip -l -v "${ZIPFILE}" >"${ZIPFILE}.INDX"

ls -l "${ZIPFILE}.INDX"
