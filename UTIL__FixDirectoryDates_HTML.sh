#!/bin/sh

BASE=`basename "$0" ".sh" `
TMP="/tmp/tmp.$$.${BASE}"		; rm -f ${TMP}

START=`pwd`
LOG_NoMATCH="${START}/${BASE}__NoMATCH.txt"
LOG_MultiMATCH="${START}/${BASE}__MultiMATCH.txt"
LOG="${START}/${BASE}.log"
#LOG_MultiMATCH="${START}/${BASE}__MultiMATCH.txt"

rm -fv "${LOG_NoMATCH}"
rm -fv "${LOG_MultiMATCH}"

LOCATION="/DB001_F5/CONSIDER__Various"
#LOCATION="/DB001_F2/Oasis/bin"

setDateFromHtmlSingle()
{
	rm -f ${TMP}.dirtree
	find "${dir}" -type d -print | sort -r >${TMP}.dirtree
	while read thisdir
	do
		touch --reference="${thisHtml}" "${thisdir}"
		ls -ld "${thisdir}" | awk '{ printf("\t %s\n", $0 ) ; }'
	done < ${TMP}.dirtree
	ls -ld "${thisHtml}" | awk '{ printf("\t %s\n", $0 ) ; }'
}


rm -fv "${TMP}"

{
ls -ld "${LOCATION}"

cd "${LOCATION}"
find -P . -type d -name '*_files' -print | 
	sed 's+^\./++' |
	sort >${TMP}
	#head -5 |

if [ ! -s "${TMP}" ] ; then  echo "\n\t Did not find any *_files directories associated with HTML files.\n Bye!\n" ; exit 0 ; fi

count=`wc -l "${TMP}" | awk '{ print $1 }' `
while read dir
do
	if [ -z "${dir}" ] ; then  exit 0 ; fi

	echo " [${count}] DIR:  ${dir} ..." >&2
	pref=`echo "${dir}" | sed 's+_files$++' `

	rm -f ${TMP}.html

	ls -1d "${pref}".[Hh][Tt][Mm] 2>>/dev/null >${TMP}.html
	if [ ! -s ${TMP}.html ]
	then
		ls -1d "${pref}".[Hh][Tt][Mm][Ll] 2>>/dev/null >${TMP}.html
	fi

	testor=`wc -l ${TMP}.html | awk '{ print $1 }' `
	case ${testor} in
		0 )	
			#echo "\t getDateFromDirContents"
			echo "${LOCATION}/${dir}" >>"${LOG_NoMATCH}"
			;;
		1 )	
			thisHtml=`head -1 ${TMP}.html `
			#echo "\t getDateFromSingle"
			setDateFromHtmlSingle
			;;
		* )	
			echo "#\t getDateFromHtmlMulti" >&2
			echo "${LOCATION}/${dir}" >>"${LOG_MultiMATCH}"

			#mv -fv ${TMP}.html ${TMP}.multi
			#while read althtml
			#do
			#	echo "${althtml}" >${TMP}.html
			#	suf=`echo "${althtml}" | awk -F \. '{ print $NF }' `
			#	dir=`echo "${althtml}" | eval sed \'s+\\.${suf}\$++\' `_files
			#	#echo " ====  dir= ${dir}    ||   althtml= ${althtml}" >&2
			#	setDateFromHtmlSingle
			#done <${TMP}.multi
			;;
	esac
	count=`expr ${count} - 1 `
done <${TMP}

if [ -s "${LOG_NoMATCH}" ]
then
	ls -l "${LOG_NoMATCH}"
else
	rm -fv "${LOG_NoMATCH}"
fi

if [ -s "${LOG_MultiMATCH}" ]
then
	ls -l "${LOG_MultiMATCH}"
else
	rm -fv "${LOG_MultiMATCH}"
fi

#if [ -s "${LOG_MultiMATCH}" ]
#then
#	ls -l "${LOG_MultiMATCH}"
#else
#	rm -fv "${LOG_MultiMATCH}"
#fi

} >"${LOG}"
