#!/bin/bash

####################################################################################################
###
###	$Id: $
###
###	Report scripts where specified flow-control words have been used, and count of such files.
###
####################################################################################################

BASE=$(basename "$0" ".sh" )
TMP=/tmp/${BASE}.tmp

flowcontrol="if for while until case"

cd $Oasis/bin

find . -mindepth 1 -maxdepth 1 -name '*.sh' -print 2>>/dev/null | cut -c3- | sort >"${TMP}"
count=$(wc -l "${TMP}" | awk '{ print $1 }' )

rm -f "${TMP}.locate."*
rm -f "${BASE}.locate"

while read line
do
	printf " [${count}]  '${line}' ...\n" >&2

	freq="${line}"

	for control in ${flowcontrol}
	do
		rm -f "${TMP}.raw"
		grep --with-filename "${control} " "${line}" >"${TMP}.raw"

		if [ -s "${TMP}.raw" ]
		then
			freq="${freq}|$(wc -l "${TMP}.raw" | awk '{ print $1 }' )"
			cat "${TMP}.raw" >>"${TMP}.locate.${control}"
		else
			freq="${freq}|0"
		fi
	done

	testor="$(echo "${freq}" | grep '|' )"
	if [ -n "${testor}" ]
	then
		echo "${freq}" | awk -v flow="dum ${flowcontrol}" 'BEGIN{
				split(flow, cntl) ;
			}{
				n=split($0, vals, "|") ;
				det=""
				for( i=2 ; i<=n ; i++ ){
					if( vals[i] != 0 ){
						det=sprintf("%s\n\t%3d  %s", det, vals[i], cntl[i] ) ;
					} ;
				} ;
				if( det != "" ){
					printf("\n%s%s\n", vals[1], det ) ;
				} ;
				exit ;
			}'
	fi
	count=$(expr ${count} - 1 )
done  <"${TMP}" >"${BASE}.locate"

echo ""

for control in ${flowcontrol}
do
	if [ -s "${TMP}.locate.${control}" ]
	then
		mv "${TMP}.locate.${control}" "${BASE}.locate.${control}"
		ls -l "${BASE}.locate.${control}"
		wc -l "${BASE}.locate.${control}"
		echo ""
	fi
done

mv ${TMP} ${BASE}.scanned

exit 0
exit 0
exit 0


#########################################################################################
#########################################################################################



for file in `cat ${TMP} `
do
	awk -v testor="{" '{ if( index($0, testor ) != 0 ){ print $0 } ; }' ${file} >${TMP}.locate
	if [ -s ${TMP}.locate ] ; then echo "${file}" ; fi
done | sort | uniq >${TMP}
	cat ${TMP}
	wc -l ${TMP}
	echo "\n\t '{' - Hit return to continue ...\c" ; read k

for file in `cat ${TMP} `
do
	awk -v testor="(" '{ if( index($0, testor ) != 0 ){ print $0 } ; }' ${file} >${TMP}.locate
	if [ -s ${TMP}.locate ] ; then echo "${file}" ; fi
done | sort | uniq >${TMP}
	cat ${TMP}
	wc -l ${TMP}
	echo "\n\t '(' - Hit return to continue ...\c" ; read k

for file in `cat ${TMP} `
do
	awk -v testor="[" '{ if( index($0, testor ) != 0 ){ print $0 } ; }' ${file} >${TMP}.locate
	if [ -s ${TMP}.locate ] ; then echo "${file}" ; fi
done | sort | uniq >${TMP}
	cat ${TMP}
	wc -l ${TMP}
	echo "\n\t '[' - Hit return to continue ...\c" ; read k

