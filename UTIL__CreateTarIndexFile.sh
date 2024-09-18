#!/bin/sh

TARFILE="$1"

case "${TARFILE}" in
	*.tar ) if [ ! -s "${TARFILE}" ] ; then  echo "\n\t Unable to locate file '${TARFILE}'.\n Bye!\n" ; exit 1 ; fi ;;
	* ) echo "\n\t This may only be used to create a custom-formatted index file of a specified tar.\n\t The index is reverse alphanum sorted with all directory file references segregated at bottom of the list.\n" ; exit 1 ;;
esac
		

tar tvf "${TARFILE}" | sort -k6.1,7.0 -r >"${TARFILE}.INDX"

grep -v '/$' "${TARFILE}.INDX" >"${TARFILE}.INDX.f"

grep '/$' "${TARFILE}.INDX" >"${TARFILE}.INDX.d"

cat "${TARFILE}.INDX.f" "${TARFILE}.INDX.d" >"${TARFILE}.INDX"

rm -f "${TARFILE}.INDX.f" "${TARFILE}.INDX.d"

ls -l "${TARFILE}.INDX"
