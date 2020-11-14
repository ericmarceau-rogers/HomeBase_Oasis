#!/bin/sh

###	$Id: OS_Admin__PartitionIndex_Make.sh,v 1.1 2020/11/14 04:09:55 root Exp $
###	Script to create index of all files on chosen partitions, as well as separate file lists for each of a wide range of specific file types by suffix.

PATH="/DB001_F2/OasisBin:/DB001_F2/OasisBin/bin:/home/root_TMP/bin:${PATH}" ; export PATH

TMPB=/tmp/`basename $0 ".sh" `.tmp
rm -f ${TMPB}.*
TMPF=${TMPB}.$$

rm -f ${TMPF}

me=`who | grep '(:0)' | awk '{ print $1 }' `

now=`date +%Y%m%d%H%M%S`

doStat=0
allTypes=0
fullSys=0

while [ $# -gt 0 ]
do
	case $1 in
		--doStat )	doStat=1	; shift ;;
		--allTypes )	allTypes=1	; shift ;;
		--fullSys )	fullSys=1	; shift ;;
		* )	echo "\n\t Invalid parameter '$1' used.\n\n Bye!\n" ; exit 1
	esac
done

drvMount=""
case `hostname` in
	OasisMega1 )
		driveIndex=1
		;;
	OasisMega2 )
		driveIndex=2
		;;
	OasisMidi )
		driveIndex=3
		;;
	OasisMini )
		driveIndex=4
		;;
	OasisBackup )
		echo "\n\t There are no plans to expand capabilities to perform indexing on these backup partitions.\n Bye!\n" ; exit 0
		;;
esac

PartitionList=`cd / ; ls -d DB00${driveIndex}_F?`
echo "\n\t Scanning Partitions:  "${PartitionList}" ...\n"

if [ ${doStat} -eq 0 ]
then
	echo "\t FYI  -  If 'stat' report for files is required, use '--doStat' option on the command line ..."
fi

if [ ${allTypes} -eq 0 ]
then
	echo "\t FYI  -  If lists for all defined file types is required, use '--allTypes' option on the command line ..."
fi

if [ ${fullSys} -eq 0 ]
then
	echo "\t FYI  -  If lists for defined file types needs to inclued OS files, use '--fullSys' option on the command line ..."
fi

if [ -z "${PartitionList}" ]
then
	echo "\n\t Did not find any partitions with the expected DB00\?_F\? label format. Abandoning process.  Bye!\n" ; exit 1
else
	list=""
	for partition in `echo ${PartitionList} `
	do
		echo "\n\t Create index for partition '${partition}' ? [y|N] => \c"
		read k
		if [ -z "$k" ]
		then	k="N"
		fi
		case ${k} in
			y* | Y* )	list="${list} ${partition}"
				;;
			* )		list="${list}"
				;;
		esac
	done

	if [ -z "${list}" ]
	then
		echo "\n\t No partitions selected for indexing.  Bye!\n" ; exit 0
	else
		PartitionList="${list}"
	fi
fi


#################################################################################################
doStatLst()
{
	### extracted stat reporting logic to independant tool:   statLst.sh
	waitJob=0 ; export waitJob

	statLst.sh "${FileList}" "${FileBase}.d" &
	waitJob=`ps -ef | grep "${DRIVE}" | grep 'statLst.sh' | awk '{ print $2 }' `

	echo "`date`  Waiting for background job to complete 'stat report for all files on this partition [PID ${waitJob}] ..." >&2
	wait ${waitJob}

	echo "\t ... done." >&2
}	#doStatLst()


#################################################################################################
getListRemainder_A()
{
	rm -f ${TMPF}.remainder
	diff --suppress-common-lines ${FileList}.2 ${DetDIR}/${FileBase}_${fType} | grep '^<' | cut -c3- >${TMPF}.remainder

#echo "\n	`wc -l ${FileList}.2`"			; head -20 ${FileList}.2
#echo "\n	`wc -l ${DetDIR}/${FileBase}_${fType}`"	; head -20 ${DetDIR}/${FileBase}_${fType}
#echo "\n	`wc -l ${TMPF}.remainder`"		; head -20 ${TMPF}.remainder			; ls -l ${DetDIR}* ; exit 1

	if [ -s ${TMPF}.remainder ]
	then
		mv ${TMPF}.remainder "${FileList}.2"
	fi
}	#getListRemainder_A()


#################################################################################################
getListRemainder_B()
{
	NoExtractList="${FileList}.REMAINDER"
	rm -f ${NoExtractList}

	{	eval grep -v \'\\\.${fType}\$\' "${FileList}.2" |
		eval grep -v \'\\\.${fTypeU}\$\'		|
		eval grep -v \'\\\.${fType}\~\$\'		|
		eval grep -v \'\\\.${fTypeU}\~\$\'
	} | grep -v '_files$' | sort | uniq > "${NoExtractList}"

	mv "${NoExtractList}" "${FileList}.2"
}	#getListRemainder_B()


#################################################################################################
getFileTypeList()
{
	fTypeU=`echo ${fType} | tr '[a-z]' '[A-Z]' `
#echo "\t NoExtractList = ${NoExtractList}"

	echo "\t Extracting type ${fType} ..."
	{
		eval grep \'\\\.${fType}\$\' "${FileList}.2"   
		eval grep \'\\\.${fTypeU}\$\' "${FileList}.2" 
		eval grep \'\\\.${fType}\~\$\' "${FileList}.2"   
		eval grep \'\\\.${fTypeU}\~\$\' "${FileList}.2" 
	} | grep -v '_files$' | sort | uniq >${DetDIR}/${FileBase}_${fType}

	if [ -s ${DetDIR}/${FileBase}_${fType} ]
	then
		#testor=`grep '\[' ${DetDIR}/${FileBase}_${fType} | head -1 `
		testor=`awk '{ n=split($0,v,"/") ; print v[n] }' ${DetDIR}/${FileBase}_${fType} | grep '\[' | head -1 `

		if [ -n "${testor}" ]
		then
			#
			###	This step is taken because the below grep sequence reports an error, 
			###	causing empty lists to be created, breaking the step-wise process.
			#
			echo "\t\t Alternate triage step due to presence of '[' in file name(s) ..."

			getListRemainder_A

			mv ${DetDIR}/${FileBase}_${fType} ${DetDIR}/${FileBase}_${fType}.bad
		else
#echo "\t NoExtractList = ${NoExtractList}"
			getListRemainder_B
		fi
	else
		rm -f ${DetDIR}/${FileBase}_${fType}
#echo "\t NoExtractList = ${NoExtractList}"
	fi
}	#getFileTypeList()


#################################################################################################
probeAndReportOtherTypes()
{
#
###	Create report of details using 'file' command for files which are not of know terminator string type 
#
	{ 
		cat "${FileList}.2" |
		while read line
		do
			dat=`file "${line}" `
			echo "${dat}"
		done
	} >"${DetDIR}/${FileBase}.others_raw.details"

	#
	###	The following logic is unusable for reason that it fails due to filename conditions.
	#
	#{
	#	xargs -I{} file '{}' < ${FileList}.2
	#} >"${DetDIR}/${FileBase}.others_raw.details"
	

#
###	Create report of Symbolic Links not captured by other file type reports
#
	grep    'symbolic link to'			"${DetDIR}/${FileBase}.others_raw.details"  >"${DetDIR}/${FileBase}.others.links"
	grep    '\: empty'				"${DetDIR}/${FileBase}.others_raw.details"  >"${DetDIR}/${FileBase}.others.data"
	grep    '\: data'				"${DetDIR}/${FileBase}.others_raw.details"  >"${DetDIR}/${FileBase}.others.data"
	grep    '\: gzip compressed data'		"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: PNG image data'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: Web Open Font Format'		"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: JPEG image data'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: GIF image data'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: dBase III DBT'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: dBase IV DBT'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: DOS EPS Binary File Postscript'	"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: ELF '				"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: EPUB document'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: exported SGML'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: GIMP XCF image data'		"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: GNU message catalog'		"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: GRUB2 font'				"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: HTML document'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: ISO-8859 text'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: ISO 9660 '				"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: ISO Media'				"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: Macromedia Flash data'		"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: MS-DOS executable'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: MS Windows icon resource'		"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: PC bitmap'				"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: PE32 executable'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: RPM v3.0 bin'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: shared library'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: UTF-8 Unicode'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: WordPerfect'			"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: Zip '				"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"
	grep    '\: zlib '				"${DetDIR}/${FileBase}.others_raw.details" >>"${DetDIR}/${FileBase}.others.data"

	# Next line must be last in sequence because of 'false positive' on presence for 'data' type
	grep    'ASCII text'			"${DetDIR}/${FileBase}.others_raw.details" >"${DetDIR}/${FileBase}.others.ASCII"

	for suf in links data ASCII
	do
		if [ ! -s "${DetDIR}/${FileBase}.others.${suf}" ]
		then
			rm -f "${DetDIR}/${FileBase}.others.${suf}"
		fi
	done

	grep -v 'symbolic link to' "${DetDIR}/${FileBase}.others_raw.details"   |
	grep -v '\: empty'							|
	grep -v '\: data'         						|
	grep -v '\: gzip compressed data'					|
	grep -v '\: PNG image data'						|
	grep -v '\: Web Open Font Format'					|
	grep -v '\: JPEG image data'						|
	grep -v '\: GIF image data'						|
	grep -v '\: dBase III DBT'						|
	grep -v '\: dBase IV DBT'						|
	grep -v '\: DOS EPS Binary File Postscript'				|
	grep -v '\: ELF '							|
	grep -v '\: EPUB document'						|
	grep -v '\: exported SGML'						|
	grep -v '\: GIMP XCF image data'					|
	grep -v '\: GNU message catalog'					|
	grep -v '\: GRUB2 font'							|
	grep -v '\: HTML document'						|
	grep -v '\: ISO-8859 text'						|
	grep -v '\: ISO 9660 '							|
	grep -v '\: ISO Media'							|
	grep -v '\: Macromedia Flash data'					|
	grep -v '\: MS-DOS executable'						|
	grep -v '\: MS Windows icon resource'					|
	grep -v '\: PC bitmap'							|
	grep -v '\: PE32 executable'						|
	grep -v '\: RPM v3.0 bin'						|
	grep -v '\: shared library'						|
	grep -v '\: UTF-8 Unicode'						|
	grep -v '\: WordPerfect'						|
	grep -v '\: Zip '							|
	grep -v '\: zlib '							|
	grep -v 'ASCII text'      >"${DetDIR}/${FileBase}.others_raw"

}	#probeAndReportOtherTypes()


#################################################################################################
createPartitionFileIndex()
{
	echo "\n\t #####################################################################################\n\t ${DRIVE} ..."

	echo "\t Purging old files ..."
	rm -f	  ${drvMount}/${dev}/0-${dev}-*.files*
	rm -rf	  ${drvMount}/${dev}/0-${dev}-*.details

	FileBase="0-${dev}-${now}.files"
	FileList="${drvMount}/${dev}/${FileBase}"
	rm -f ${FileList} ${FileList}.2

	echo "\n`date`  Searching on ${DRIVE} ..."

	SearchDir="."

	if [ "${DRIVE}" = "DB001_F1" ]
	then
		SearchDir="/"
	fi

	###
	### -xdev supercedes -mount option to prevent crossing onto other partitions
	###
	find -P  ${SearchDir}  -xdev  \( ! -type d \)  -print >${TMPF}
	find -P  ${SearchDir}  -xdev       -type d     -print | sort -r >"${FileList}.d"

	grep '\[' "${FileList}.d" >"${FileList}.d.square"

	echo "`date`  Creating sorted list ... '${FileList}' ..."
	sort ${TMPF} | uniq > "${FileList}"

	if [ ${doStat} -eq 1 ]
	then
		doStatLst | awk '{ printf("\t\t %s\n", $0 ) }'
	else
		echo "`date`  Creation of 'stat' report was not requested on command line ..."
	fi

	echo "`date`  Extracting list of system-only files ... '${FileList}-SYS' ..."
	{
		grep  '^./bin' "${FileList}"
		grep  '^./boot' "${FileList}"
		grep  '^./cdrom' "${FileList}"
		grep  '^./dev' "${FileList}"
		grep  '^./etc' "${FileList}"
		grep  '^./lib' "${FileList}"
		grep  '^./lib64' "${FileList}"
		grep  '^./media' "${FileList}"
		grep  '^./mnt' "${FileList}"
		grep  '^./lost+found' "${FileList}"
		grep  '^./proc' "${FileList}"
		grep  '^./run' "${FileList}"
		grep  '^./sbin' "${FileList}"
		grep  '^./srv' "${FileList}"
		grep  '^./sys' "${FileList}"
		grep  '^./var' "${FileList}"
		grep  '^./usr' "${FileList}"
	} >"${FileList}-SYS"


	echo "`date`  Extracting list of NON-system files ... '${FileList}-NON' ..."

	grep -v '^./bin' "${FileList}"	|
	grep -v '^./boot'		|
	grep -v '^./cdrom'		|
	grep -v '^./dev'		|
	grep -v '^./etc'		|
	grep -v '^./lib'		|
	grep -v '^./lib64'		|
	grep -v '^./media'		|
	grep -v '^./mnt'		|
	grep -v '^./lost+found'		|
	grep -v '^./proc'		|
	grep -v '^./run'		|
	grep -v '^./sbin'		|
	grep -v '^./srv'		|
	grep -v '^./sys'		|
	grep -v '^./var'		|
	grep -v '^./usr' >"${FileList}-NON"

	DetDIR="${drvMount}/${dev}/0-${dev}-${now}.details"
	mkdir	${DetDIR}
	echo	${DetDir}

	#  .record.gz   .org .com .net
	echo "`date`  Extracting lists for various file types ... "

	if [ ${fullSys} -eq 1 ]
	then
		sort "${FileList}"	>"${FileList}.2"
	else
		sort "${FileList}-NON"	>"${FileList}.2"
	fi
NoExtractList="TEST"

	###	Build lists of files by type for subsequent type-specific processing for various characters causing problematic name conditions.
	if [ ${allTypes} -eq 1 ]
	then
		for fType in   al alias ani asx atb ati avi bash bashrc bfc bin bmp bs c cf cfg cfs class conf config crt csh cshrc css ctb cti dat db dbf deb defaults del desktop directory dirs dll doc docbook docitem docx dtd esi exe flac flv fmt fw gen gif gpg h heu hpgl hpp ht htm html inc inf info ini iso jar java jfc jigdo jpg jpeg js json jwl key keyring keystore ksh ktb kti list locale lock log lsp lst m3u m4 mab manifest md metadata metalink mid mk4 mkv mov mp3 mp4 mpeg mpg msf nfo odb odt ogg ogv opml orig otf otp ots ott out pack patch pc pdf pem pfb pfm ph php pl plg pm png pod ppd pptx pr pro profile ps pset py pyc pyo rb rc rdb rdf report res rtf sav save sbstore scale sdb sdv sh so sol sqlite src srt stderr stdout svg swf tar tcsh tdb template theme thm tiff tmp tmpl torrent tree ttb ttf txt url vch vim vlpset wav webp wma wmf wmv woff xba xbel xcu xdl xlb xlc xls xlsx xml xpi xpt xsd xsl xslt xspf xul         gz jsonlz4 lz4 mozlz4 swz taz tgz xz zip zsh zsync
		do
			getFileTypeList
		done
	else
		#
		###	These types seem to most frequently be problematic for the logic used in the function.
		###	Best to clear up issues with those before doing using '--allTypes' option.
		#
		for fType in   gz jsonlz4 lz4 mozlz4 swz taz tgz xz zip zsh zsync
		do
			getFileTypeList
		done
	fi
	echo ""
#echo "\t NoExtractList = ${NoExtractList}"
	

	if [ ${allTypes} -eq 1 ]
	then
		probeAndReportOtherTypes
	fi
	

#
###	FUTURES???
#
#	echo "Extracting scripts ... '${FileList}' ..."
#	grep '\.sh$' "${FileList}" >"${DetDIR}/${FileList}.scripts"
	

#
###	Loop pass cleanup
#
	echo "\n List of files containing clean name strings:"
	rm -f ${TMPF}.typeLists
	ls -d ${DetDIR}/* | grep -v '\.bad\$' >${TMPF}.typeLists
	if [ -s ${TMPF}.typeLists ]
	then
		wc -l `cat ${TMPF}.typeLists `
		echo ""
	fi

	echo "\n List of files containing problematic characters in name strings:"
	rm -f ${TMPF}.typeLists
	ls -d ${DetDIR}/* | grep    '\.bad\$' >${TMPF}.typeLists
	if [ -s ${TMPF}.typeLists ]
	then
		wc -l `cat ${TMPF}.typeLists `
	fi

	rm -f ${TMPF} ${TMPF}.typeLists
	rm -f ${FileList} ${FileList}.2
	echo "`date`  DONE  -  Indexing for partition '${dev}' ..."
}	#createPartitionFileIndex()


####################################################################################################
####################################################################################################


for dev in `echo ${PartitionList} `
do
  DRIVE="/${dev}"

  if [ -d ${DRIVE} ]
  then
    cd ${DRIVE}

    if [ $? -eq 0 ] ;
    then
	#echo ${DRIVE}
        createPartitionFileIndex
    else
	echo "\n\t  ${dev} is not a partition label.  Skipped ...\n"
    fi
  fi

done #dev

echo "\n\t List of indexing files created:\n"

for dev in `echo ${PartitionList} `
do
	DRIVE="/${dev}"
	ls -ld ${DRIVE}/0-DB*
	echo ""
done

exit 0
exit 0
exit 0
