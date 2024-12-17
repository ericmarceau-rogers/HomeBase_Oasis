#!/bin/bash
#set -x

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: COMPARE+PURGE.sh,v 1.6 2024/12/17 19:35:31 root Exp root $
###
###	Script to compare files in current directory with those in predefined script directories or in a user-defined reference directory.  The script will then present the differences where relevant, purge from current if identical, offer move command to add missing items to the reference directory.
###
###	Some logic and functions have been disabled because the script
###
###		compareLineByLineCharacterDiff.sh
###
###	has been found to have defective logic which MUST be revisited/reviewed/modified. 
###	That was intended for additional drill-down to identify more specifically the nature of
###	the differences and suggest more appropriate context-specific options/actions.
###
####################################################################################################


PATH=".:${PATH}" ; export PATH

BASE=$(basename "$0" ".sh" | sed 's+\ ++g' )
TMP="/tmp/${BASE}.tmp"
rm -f ${TMP}
rm -f ${TMP}.compare

StartDIR=$(pwd)

DEFERRED="${StartDIR}/${BASE}.deferred"
rm -f "${DEFERRED}"

#CodeROOT="/media/ericthered/DB002_F2/DB004_F1/Oasis/"
#CodeROOT="/DB001_F2/home"
#CodeROOT="/DB001_F4/LOCAL__Documents_NonBook/ericthered.Desktop"
#CodeROOT="/DB001_F4/LOCAL__Documents_NonBook/ericthered"
#CodeROOT="/DB001_F4/LOCAL__Platform/RawHarvest/HardwareConfiguration"
#CodeROOT="/DB001_F2/home/ericthered.PostInstall/00__01__PostInstall_Day0"
#CodeROOT="/DB001_F4/LOCAL__Distro"
#CodeROOT="/DB001_F2/LO"
#CodeROOT="/DB001_F7/DTM_CodeLib/xdvmsrv_archive"
#CodeROOT="/DB001_F2/Oasis"
CodeROOT="/DB001_F2/LO_Index/TOOLS__Compare"

doAllBins=0

DBGd=0
DBGf=0	###
DBGx=0

VERBd=1
VERBf=1
VERBl=0

#################################################################################################################
#################################################################################################################
selectYesNo()
{
	result=0

	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  selectYesNo() ..." >&2 ; fi

	read ans
	if [ -z "${ans}" ] ; then  ans="N" ; fi

	case ${ans} in
		y* | Y* ) result=1 ;; #echo -e " Proceeding ..." ;;
	      	* )	  ;; #echo -e "\n Bye!\n" ; exit 1 ;;
	esac
	return ${result}
}	#selectYesNo()


#################################################################################################################
#################################################################################################################
promptForReferencePath()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  promptForReferencePath() ..." >&2 ; fi

	echo -e "\n\t Enter the full path to the directory containing contents \n\t which will be compared with those in the current directory's \n\t\t => \c"
	read fullPathToReference
	if [ -z "${fullPathToReference}" ]
	then
		echo -e "\n\t\t NULL ENTRY => Process abandoned. \n\n Bye!\n"
		exit 0
	fi

	if [ ! -d "${fullPathToReference}" ]
	then
		echo -e "\n\t\t Directory '${fullPathToReference}' not found => Process abandoned. \n\n Bye!\n"
		exit 0
	fi

	CodeROOT=$(dirname "${fullPathToReference}" )
	dREF=$(basename "${fullPathToReference}" )

	#echo -e "\t REF = ${fullPathToReference}   (initial capture)" >&2
}	#promptForReferencePath()


#################################################################################################################
#################################################################################################################
selectOneOf()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  selectOneOf() ..." >&2 ; fi

	doBreak=0

	echo -e "\n\t Select REFERENCE code library

	 1 - bin_Admin [default]
	 2 - bin_Dev
	 3 - bin_Eval
	 4 - bin_FW
	 5 - bin_OS
	 6 - bin_User
	 7 - bin_Util
	 8 - bin_Sec

	 Z - Manual Entry for Special Case

	 0 - '--batchAll'
	\n	 Enter selection [1-8|Z|q] => \c"

	read ans
	if [ -z "${ans}" ] ; then  ans="1" ; fi

	case ${ans} in
		0 )	$0 --batchAll   ; exit $? ;;
		1 )	dREF="bin_Admin"; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		2 )	dREF="bin_Dev"	; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		3 )	dREF="bin_Eval"	; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		4 )	dREF="bin_FW"	; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		5 )	dREF="bin_OS"	; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		6 )	dREF="bin_User"	; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		7 )	dREF="bin_Util"	; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		8 )	dREF="bin_Sec"	; CodeROOT="/DB001_F2/LO" ; fullPathToReference="${CodeROOT}/${dREF}" ; doBreak=1 ;;
		z* | Z* )	
			promptForReferencePath

			#echo -e "\t REF = ${fullPathToReference}   (case pre-break)" >&2
			doBreak=1 ;;
	  q* | Q* )	echo -e "\n Bye!\n" ; exit 0 ;;
		* )	echo -e "\n\t Option entered is invalid. Please re-enter => \c" ;;
	esac

	#echo -e "\t\t SANITY CHECK\n"
	#echo -e "\t REF = ${fullPathToReference}   (function pre-exit)" >&2
}	#selectOneOf()


#################################################################################################################
#################################################################################################################
dirs_NewerInReference()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  dirs_NewerInReference() ..." >&2 ; fi

	frame="NewerInReference"

	while read fileB
	do
		if [ ${VERBd} -eq 1 ] ; then  echo -e "\t ------------ \n\t  ${fileB} ..." ; fi

		dirBase=$(basename "${fileB}" )

		if [ "${dirBase}" = "${file}" ]
		then
			if [ ${DBGd} -eq 1 ] ; then  echo -e "\t context= ${context}" ; fi
if [ ${DBGd} -eq 1 ] ; then  set -x ; fi
			if [ ${VERBd} -eq 1 ] ; then  echo -e "\t =============================================================================" ; fi
			#if [ ${VERBd} -eq 1 ] ; then  ( ls -ld "./${fileA}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }' ; fi
			if [ ${VERBd} -eq 1 ] ; then  ( ls -ld "./${file}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }' ; fi

			##
			## FUTURES:  1) stat directory values of date and size (like files)
			##	     2) compare list of files between 2 directories
			##	     3) compare stat of files on contents of 2 directories
			##
			##   ** Possible recursive use of this program
			## 

			echo -e "\t [D] DIRECTORY__SKIPPING-MATCH (1)  '${file}' ..."
		else
			echo -e "\t [D] DIRECTORY__BASENAME_MISMATCH (1)  '${file}' ..."
		fi
if [ ${DBGd} -eq 1 ] ; then  set +x ; fi
	done <${TMP}.d
}	#dirs_NewerInReference()


#################################################################################################################
#################################################################################################################
dirs_NewerInCurrent()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  dirs_NewerInCurrent() ..." >&2 ; fi

	frame="NewerInCurrent"

	while read fileB
	do
		if [ ${VERBd} -eq 1 ] ; then  echo -e "\t ------------ \n\t  ${fileB} ..." ; fi

		dirBase=$(basename "${fileB}" )

		if [ "${dirBase}" = "${file}" ]
		then
			if [ ${DBGd} -eq 1 ] ; then  echo -e "\t context= ${context}" ; fi
if [ ${DBGd} -eq 1 ] ; then  set -x ; fi
			if [ ${VERBd} -eq 1 ] ; then  echo -e "\t =============================================================================" ; fi
			#if [ ${VERBd} -eq 1 ] ; then  ( ls -ld "./${fileA}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }' ; fi
			if [ ${VERBd} -eq 1 ] ; then  ( ls -ld "./${file}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }' ; fi

			##
			## FUTURES:  1) stat directory values of date and size (like files)
			##	     2) compare list of files between 2 directories
			##	     3) compare stat of files on contents of 2 directories
			##
			##   ** Possible recursive use of this program
			## 

			echo -e "\t [D] DIRECTORY__SKIPPING-MATCH (2)  '${file}' ..."
		else
			echo -e "\t [D] DIRECTORY__BASENAME_MISMATCH (2)  '${file}' ..."
		fi
if [ ${DBGd} -eq 1 ] ; then  set +x ; fi
	done <${TMP}.d
}	#dirs_NewerInCurrent()


#################################################################################################################
#################################################################################################################
evaluateDirs()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  evaluateDirs() ..." >&2 ; fi

	rm -f ${TMP}.d
	#find "${GOOD_REFERENCE}" -xdev -maxdepth 1 -mindepth 1 -type d -name "${file}" -newer "./${file}" -print >${TMP} 2>>/dev/null
	find "${GOOD_REFERENCE}" -xdev -mindepth 1 -type d -name "${file}" -newer "./${file}" -print >${TMP}.d 2>>/dev/null

	if [ -s ${TMP}.d ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t   [D3A] ..." >&2 ; fi

		context="NewerInReference"
		dirs_NewerInReference
	else
		rm -f ${TMP}.d

		#FUTURES: re-code logic similar to evaluateFils
		#find . -xdev -maxdepth 1 -mindepth 1 -type d -name "${file}" -newer "${GOOD_REFERENCE}/${file}" -print >${TMP} 2>>/dev/null
		find . -xdev -mindepth 1 -type d -name "${file}" -newer "${GOOD_REFERENCE}/${file}" -print >${TMP}.d 2>>/dev/null

		if [ -s ${TMP}.d ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t   [D3B-1] ..." >&2 ; fi

			context="NewerInCurrent"
			dirs_NewerInCurrent
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t   [D3B-2] ..." >&2 ; fi

			echo -e "\t [D] DIRECTORY__REVIEW_LOWER_LEVELS  '${file}' ..."

	######################################################################################
	######################################################################################
	dummyHidden()
	{
		Dres1=$(du -sb "${file}" )
		Dres2=$(du -sb "${GOOD_REFERENCE}/${file}" )
		Dsiz1=$(echo -e ${Dres1} | awk '{ print $1 }' )
		Dsiz2=$(echo -e ${Dres2} | awk '{ print $1 }' )
		echo -e "\t\t ${Dres1}"
		echo -e "\t\t ${Dres2}"
		if [ "${Dsiz1}" = "${Dsiz2}" ]
		then
			rm -f ${TMP}.Dlist1 ${TMP}.Dlist2 ${TMP}.DlistDiff
			find "${file}" -print | sort >${TMP}.Dlist1
			( cd "${GOOD_REFERENCE}" ; find "${file}" -print | sort ) >${TMP}.Dlist2
			diff ${TMP}.Dlist1 ${TMP}.Dlist2 >${TMP}.DlistDiff
			if [ -s ${TMP}.DlistDiff ]
			then
				echo -e "\t\t DIRECTORY_DIFF__CONTENTS|${file}"
				testorD=$(wc -l ${TMP}.DlistDiff | awk '{ print $1 }' )
				if [ ${testorD} -le 30 ]
				then
					cat ${TMP}.DlistDiff | awk '{ printf("\t\t |DIFF|%s\n", $0 ) }'
				else
					echo -e "\t\t\t Too many differences [LC = ${testorD}] ..."
				fi
			else
				#echo -e "\t\t DIRECTORY_MATCH|${file}\n\t\t List of contents reported identical files ... Purge ? [y|N] => \c" ; read doPurgeDir <&2
				echo -e "\t\t DIRECTORY_MATCH|${file}\n\t\t List of contents reported identical files.  Purging ..."
				#if [ -z "${doPurgeDir}" ]
				#then
				#	doPurgeDir="N"
				#fi
				#case "${doPurgeDir}" in
				#	y* | Y* )	
						COM="rm -rvf './${file}' 2>&1 | awk '{ printf(\"\t\t ||%s\n\", $0 ) }' "
						echo "[DEFERRED]  |${COM}"
						echo ""
				#		;;
				#	* ) ;;
				#esac
			fi
		else
			echo -e "\t\t DIRECTORY_DIFF__SIZE|${file}"
		fi
	}	#dummyHidden()
	######################################################################################
	######################################################################################

		fi
	fi
}	#evaluateDirs()


#################################################################################################################
#################################################################################################################
purgeIdentical()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  purgeIdentical() ..." >&2 ; fi

	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t        [8] ..." >&2 ; fi

	echo "|${frame}|${mode}|${context}|" | awk '{ split($0,var,"|") ; printf("\t\t frame = %-17s  |  mode = %-2s  |  context = %-17s\n", var[2], var[3], var[4] ) ; }'

	###	Eliminate *_files directories corresponding to HTML files that have been purged.
	case "${fileA}" in
		*.htm | *.html | *.HTM | *.HTML )
			Hsuf=$(echo "${fileA}" | awk '{ n=split($0,var,".") ; print var[n] }' )
			HdirBase=$(basename "${fileA}" ".${Hsuf}" )
			HdirName="${HdirBase}_files"
			if [ -d "${HdirName}" ]
			then
				#echo -e "	*** PURGE ***  rm -rfv \"${HdirName}\" "
				rm -rfv "${HdirName}" 2>&1 | awk '{ printf("\t\t\t HTML| %s\n", $0 ) }'
			fi
			;;
		* ) ;;
	esac

	rm  -v "./${fileA}" 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
	echo ""
}	#purgeIdentical()


#################################################################################################################
#################################################################################################################
reportAndPurge()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  reportAndPurge() ..." >&2 ; fi

	if [ ${VERBf} -eq 1 ] ; then  echo -e "\t =============================================================================" ; fi
	if [ ${VERBf} -eq 1 ] ; then  ( ls -ld "./${fileA}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }' ; fi

	if [ ${DBGf} -eq 1 ] ; then  test -f ${TMP}.diff && cat ${TMP}.diff ; fi

#	if [ ${mode} -eq 1 -a "${testA}" = "${testB}" ]
#	if [ ${mode} -eq 3 -a "${testA}" = "${testB}" ]
	if [ -n "$(echo ${mode} | awk '/[15]/{ print $0 }' )" ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t       [7-1] ..." >&2 ; fi

		if [  "${testA}" = "${testB}" ]
		then
			echo -e "\t PURGEABLE_IDENTICAL (modTime)  '${fileA}' ..."
		else
#			if [ ${mode} -eq 2 -a "${testC}" = "${testD}" ]
#			if [ ${mode} -eq 4 -a "${testC}" = "${testD}" ]
#			then
#				echo -e "\t PURGEABLE_IDENTICAL (chg)  '${fileA}' ..."
#			else
				echo -e "\t PURGEABLE_IDENTICAL  '${fileA}' (non-impacting timestamp difference)..."
#			fi
		fi
		purgeIdentical
	else
		if [ ${isVideo} -eq 1 -o ${isImage} -eq 1 -o ${isText} -eq 0 ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t       [7-2a] ..." >&2 ; fi

			purgeIdentical
		else
			sumA=$(b2sum -b "${fileA}" | awk '{ print $1 }' )
			sumB=$(b2sum -b "${fileB}" | awk '{ print $1 }' )

			if [ "${sumA}" = "${sumB}" ]
			then
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t       [7-2a-1] ..." >&2 ; fi

				echo -e "\t IDENTICAL results reported by 'b2sum' for  '${fileA}' ..."
				purgeIdentical
			else
				sumK=$(md5sum -b "${fileA}" | awk '{ print $1 }' )
				sumL=$(md5sum -b "${fileB}" | awk '{ print $1 }' )
				if [ "${sumK}" = "${sumL}" ]
				then
					if [ ${VERBl} -eq 1 ] ; then  echo -e "\t       [7-2a-1b] ..." >&2 ; fi

					echo -e "\t IDENTICAL results reported by 'md5sum' for  '${fileA}' ..."
					purgeIdentical
				else
					if [ ${VERBl} -eq 1 ] ; then  echo -e "\t       [7-2a-2] ..." >&2 ; fi

					echo -e "\t NON-MATCHING CONTENT:  Filename conflict identified by 'b2sum' and 'md5sum' discrepancy for  '${fileA}' ..."
					echo "|Different|${mode}|${context}|" | awk '{ split($0,var,"|") ; printf("\t\t frame = %-17s  |  mode = %-2s  |  context = %-17s\n", var[2], var[3], var[4] ) ; }'
					echo -e "\t\t\t No action taken ..."
	###
	###	Logic of 'compareLineByLineCharacterDiff.sh' is questionable and needs a review/rewrite
	###
	#				compareLineByLineCharacterDiff.sh --lineNum --fileCur "${fileA}" --fileRef "${fileB}"
					( ls -ld "./${fileA}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
				fi
			fi
		fi
	fi
}	#reportAndPurge()


#################################################################################################################
#################################################################################################################
diffImg()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  diffImg() ..." >&2 ; fi

	isImage=1
	if [ "${testE}" = "${testF}" ]
	then
		## FUTURES:  expand logic to detect rotated image at any of 90/180/270 degrees.

		sumA=$(md5sum -b "${fileA}" | awk '{ print $1 }' )
		sumB=$(md5sum -b "${fileB}" | awk '{ print $1 }' )

		if [ "${sumA}" = "${sumB}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6A-1a] ..." >&2 ; fi
			echo -e "\t [Image] IDENTICAL results reported by 'md5sum' ..."
			rm -f ${TMP}.diff
		else
			if [ -n "${IDIFF}" ]
			then
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6A-1b1] ..." >&2 ; fi
				${IDIFF}  "./${fileA}" "${fileB}" | awk '{ printf("\t %s\n", $0 ) }' >${TMP}.diff
				if [ -z "$(tail -1 ${TMP}.diff | grep 'FAIL' )" ]
				then
					echo -e "\t [Image] IDENTICAL results reported by 'idiff' ..."
					rm -f ${TMP}.diff
				fi
			else
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6A-1b2] ..." >&2 ; fi
				echo -e "\t\t Unable to confirm identical content; missing 'idiff'" >${TMP}.diff
			fi
		fi
	else
		#echo -e "\t\t [Image] NON-IDENTICAL sizes:  ${testE} vs ${testF}" >${TMP}.diff
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6A-2] ..." >&2 ; fi

		echo -e "\t\t Different sizes (image):  ${testE} vs ${testF}" >${TMP}.diff
	fi
}	#diffImg()


#################################################################################################################
#################################################################################################################
diffVid()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  diffVid() ..." >&2 ; fi

	isVideo=1
	if [ "${testE}" = "${testF}" ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6B-1] ..." >&2 ; fi

		sumA=$(b2sum -b "${fileA}" | awk '{ print $1 }' )
		sumB=$(b2sum -b "${fileB}" | awk '{ print $1 }' )

		if [ "${sumA}" = "${sumB}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6B-1a] ..." >&2 ; fi

			echo -e "\t [Video] IDENTICAL results reported by 'b2sum' ..."
			rm -f ${TMP}.diff
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6B-1b] ..." >&2 ; fi

			#echo -e "\t\t NOTICE:   Video file detected. No logic coded to deal with comparison ..." >${TMP}.diff
			echo -e " [Video] NON-IDENTICAL results reported by 'b2sum':\n${sumA}| ${fileA}\n${sumB}| ${fileB}" >${TMP}.diff
			cat ${TMP}.diff
		fi
	else
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6B-2] ..." >&2 ; fi

		echo -e " Different sizes (video):  ${testE} vs ${testF}" >${TMP}.diff
	fi
}	#diffVid()


#################################################################################################################
#################################################################################################################
diffZip()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  diffZip() ..." >&2 ; fi

	isZip=1
	if [ "${testE}" = "${testF}" ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6C-1] ..." >&2 ; fi

		sumA=$(md5sum -b "${fileA}" | awk '{ print $1 }' )
		sumB=$(md5sum -b "${fileB}" | awk '{ print $1 }' )

		if [ "${sumA}" = "${sumB}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6C-1a] ..." >&2 ; fi

			echo -e "\t [Zip] IDENTICAL results reported by 'md5sum' ..."
			rm -f ${TMP}.diff
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6C-1b] ..." >&2 ; fi

			echo -e " [Zip] NON-IDENTICAL results reported by 'md5sum':\n${sumA}| ${fileA}\n${sumB}| ${fileB}" >${TMP}.diff
			rm -f ${TMP}.zipAl
			rm -f ${TMP}.zipBl
			unzip -l "${fileA}" >${TMP}.zipAl
			unzip -l "${fileB}" >${TMP}.zipBl
			echo -e " Content difference (zip):" >>${TMP}.diff
			diff ${TMP}.zipAl ${TMP}.zipBl >>${TMP}.diff

			#cat ${TMP}.diff
		fi
	else
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6C-2] ..." >&2 ; fi

		echo -e " Different sizes (zip):  ${testE} vs ${testF}" >${TMP}.diff

		rm -f ${TMP}.zipAl
		rm -f ${TMP}.zipBl
		unzip -l "${fileA}" >${TMP}.zipAl
		unzip -l "${fileB}" >${TMP}.zipBl
		echo -e " Content difference (zip):" >>${TMP}.diff
		diff ${TMP}.zipAl ${TMP}.zipBl >>${TMP}.diff

		#cat ${TMP}.diff
	fi
}	#diffZip()


#################################################################################################################
#################################################################################################################
diffGzip()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  diffGzip() ..." >&2 ; fi

	isGzip=1
	if [ "${testE}" = "${testF}" ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6D-1] ..." >&2 ; fi

		sumA=$(md5sum -b "${fileA}" | awk '{ print $1 }' )
		sumB=$(md5sum -b "${fileB}" | awk '{ print $1 }' )

		if [ "${sumA}" = "${sumB}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6D-1a] ..." >&2 ; fi

			echo -e "\t [Gzip] IDENTICAL results reported by 'md5sum' ..."
			rm -f ${TMP}.diff
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6D-1b] ..." >&2 ; fi

			echo -e " [Zip] NON-IDENTICAL results reported by 'md5sum':\n${sumA}| ${fileA}\n${sumB}| ${fileB}" >${TMP}.diff
			rm -f ${TMP}.gzipAl
			rm -f ${TMP}.gzipBl
			tar -tvzf "${fileA}" >${TMP}.gzipAl
			tar -tvzf "${fileB}" >${TMP}.gzipBl
			echo -e " Content difference (gzip):" >>${TMP}.diff
			diff ${TMP}.gzipAl ${TMP}.gzipBl >>${TMP}.diff

			#cat ${TMP}.diff
		fi
	else
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6D-2] ..." >&2 ; fi

		echo -e " Different sizes (gzip):  ${testE} vs ${testF}" >${TMP}.diff

		rm -f ${TMP}.gzipAl
		rm -f ${TMP}.gzipBl
		tar -tvzf "${fileA}" >${TMP}.gzipAl
		tar -tvzf "${fileB}" >${TMP}.gzipBl
		echo -e " Content difference (gzip):" >>${TMP}.diff
		diff ${TMP}.gzipAl ${TMP}.gzipBl >>${TMP}.diff

		#cat ${TMP}.diff
	fi
}	#diffGzip()


#################################################################################################################
#################################################################################################################
diffTar()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  diffTar() ..." >&2 ; fi

	isTar=1
	if [ "${testE}" = "${testF}" ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6E-1] ..." >&2 ; fi

		sumA=$(md5sum -b "${fileA}" | awk '{ print $1 }' )
		sumB=$(md5sum -b "${fileB}" | awk '{ print $1 }' )

		if [ "${sumA}" = "${sumB}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6E-1a] ..." >&2 ; fi

			echo -e "\t [Tar] IDENTICAL results reported by 'md5sum' ..."
			rm -f ${TMP}.diff
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6E-1b] ..." >&2 ; fi

			echo -e " [Tar] NON-IDENTICAL results reported by 'md5sum':\n${sumA}| ${fileA}\n${sumB}| ${fileB}" >${TMP}.diff

			rm -f ${TMP}.tarAl
			rm -f ${TMP}.tarBl
			tar -tvf "${fileA}" >${TMP}.tarAl
			tar -tvf "${fileB}" >${TMP}.tarBl
			echo -e " Content difference (tar):" >>${TMP}.diff
			diff ${TMP}.tarAl ${TMP}.tarBl >>${TMP}.diff

			#cat ${TMP}.diff
		fi
	else
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6E-2] ..." >&2 ; fi

		echo -e " Different sizes (tar):  ${testE} vs ${testF}" >${TMP}.diff

		rm -f ${TMP}.tarAl
		rm -f ${TMP}.tarBl
		tar -tvf "${fileA}" >${TMP}.tarAl
		tar -tvf "${fileB}" >${TMP}.tarBl
		echo -e " Content difference (tar):" >>${TMP}.diff
		diff ${TMP}.tarAl ${TMP}.tarBl >>${TMP}.diff

		#cat ${TMP}.diff
	fi
}	#diffTar()


#################################################################################################################
#################################################################################################################
diffBin()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  diffBin() ..." >&2 ; fi

	if [ "${testE}" = "${testF}" ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6Z-1] ..." >&2 ; fi

		## #diff --suppress-common-lines "${fileA}" "${fileB}" | awk '{ printf("\t %s\n", $0 ) }' >${TMP}.diff
		## $admin/checkBinaryType.sh --verbose --current "${fileA}" --reference "${fileB}" | awk '{ printf("\t %s\n", $0 ) }' >${TMP}.diff

		sumA=$(b2sum -b "${fileA}" | awk '{ print $1 }' )
		sumB=$(b2sum -b "${fileB}" | awk '{ print $1 }' )

		if [ "${sumA}" = "${sumB}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6Z-1a] ..." >&2 ; fi

			echo -e "\t [BinaryCode] IDENTICAL results reported by 'b2sum' ..."
			rm -f ${TMP}.diff
		else
			sumK=$(md5sum -b "${fileA}" | awk '{ print $1 }' )
			sumL=$(md5sum -b "${fileB}" | awk '{ print $1 }' )
			if [ "${sumK}" = "${sumL}" ]
			then
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6Z-1a2] ..." >&2 ; fi

				echo -e "\t [BinaryCode] IDENTICAL results reported by 'md5sum' ..."
				rm -f ${TMP}.diff
			else
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6Z-1b] ..." >&2 ; fi

				#echo -e "\t\t NOTICE:   Binary file detected. No logic coded to deal with comparison ..." >${TMP}.diff
				echo -e "\t [BinaryCode] NON-IDENTICAL results reported by 'b2sum' and 'md5sum':\n${sumA}| ${fileA}\n${sumB}| ${fileB}" >${TMP}.diff
				cat ${TMP}.diff
			fi
		fi
	else
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6Z-2] ..." >&2 ; fi

		echo -e "\t\t Different sizes (binary):  ${testE} vs ${testF}" >${TMP}.diff
	fi

	if [ ${isBin} -eq 1 ]
	then
		echo -e "\t | BINARY [Executable] ..." >&2
	else
		echo -e "\t | BINARY [Non-Executable] ..." >&2
	fi
}	#diffBin()


#################################################################################################################
#################################################################################################################
closeMatchDiff()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  closeMatchDiff() ..." >&2 ; fi

	rm -f ${TMP}.diff2
	echo -e "\t isText= ${isText} ..."
	echo -e "\t isBin= ${isBin} ..."
	
	compareLineByLineCharacterDiff.sh --fileCur "${fileA}" --fileRef "${fileB}" >${TMP}.diff2

	if [ -s ${TMP}.diff2 ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6D-1] ..." >&2 ; fi

		diffRAW="/tmp/$(basename "${fileA}" ).diff"
		diffSPC="/tmp/$(basename "${fileA}" ).diff2"
		if [ -s "${diffRAW}" ]
		then
			mv ${TMP}.diff "${diffRAW}.ext"
		else
			mv ${TMP}.diff "${diffRAW}"
		fi

		compareLineByLineCharacterDiff.sh --fileCur "${fileA}" --fileRef "${fileB}" | cut -f2 -d\| | sort | uniq >${TMP}.diff

		read dat <${TMP}.diff

		if [ "${dat}" = "0" ]
		then
			if [ ${VERBl} -eq 1 ]
			then
				echo -e "\t      [6D-1a] ..." >&2
				echo -e "\n\t COMMAND:  'compareLineByLineCharacterDiff.sh --fileCur \"${fileA}\" --fileRef \"${fileB}\" | cut -f2 -d\| | sort | uniq >${TMP}.diff' "
			fi
			echo -e "\t NOTE: *** ${TMP}.diff2 is empty after stripping 'CR' and 'LF' characters ..." >&2

			rm -f ${TMP}.diff
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t      [6D-1b] ..." >&2 ; fi
			{
			echo -e " -----------------------------------------------------------------------"
			echo -e " Additional comparison using 'compareLineByLineCharacterDiff.sh' ..."
			echo -e " COMMAND:  'compareLineByLineCharacterDiff.sh --lineNum \n\t\t --fileCur \"${fileA}\" \n\t\t --fileRef \"${fileB}\" ' \n"

			echo -e "|**START**|"
			compareLineByLineCharacterDiff.sh --lineNum --fileCur "${fileA}" --fileRef "${fileB}"
			echo -e "|**END**|"

			cnt=$(wc -l "${diffRAW}" )
			echo -e "\n REFERENCE:  '${diffRAW}'    [linecount= ${cnt}]"
			echo -e " REFERENCE:  '${diffSPC}'"
			echo -e " -----------------------------------------------------------------------"
			} | awk '{ printf("\t %s\n", $0 ) }' >${TMP}.diff
			cp -f ${TMP}.diff "${diffSPC}"
		fi
	else
		if [ ${VERBl} -eq 1 ]
		then
			echo -e "\t      [6D-2] ..." >&2
			echo -e "\n\t COMMAND:  'compareLineByLineCharacterDiff.sh --fileCur \"${fileA}\" --fileRef \"${fileB}\" ' "
		fi
		echo -e "\t NOTE: *** ${TMP}.diff2 is empty ..."

		rm -f ${TMP}.diff
	fi
}	#closeMatchDiff()


#################################################################################################################
#################################################################################################################
diffFile()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  diffFile() ..." >&2 ; fi

	#diffFIL="/tmp/$(basename "${fileA}" ).diff"
	#rm -f "${diffFIL}"
	rm -f ${TMP}.diff

	isImage=0
	isVideo=0
	isZip=0
	isGzip=0
	isTar=0
	isText=0

	if [ ${VERBl} -eq 1 ] ; then  file "${fileA}" | awk '{ printf("\t\t\t %s\n", $0 ) ; }' >&2 ; fi 

	#testTxt=$(grep '^#!' "${fileA}" | head -1 | cut -c1-120 | awk '{ if( NF == 1 ){ print $1 }else{ if( NF == 2 ){ print $1, $2 ; }else{ printf "NULL" ; } ; } ; }' )
	testTxt=$(grep '^[#][!]' "${fileA}" | head -1 | cut -c1-120 |
		awk 'BEGIN{ rv=1 ;
		}{
			if( NF == 1 ){
				print $1 ;
				rv=0 ;
			}else{
				if( NF == 2 ){
					print $1, $2 ;
					rv=0 ;
				} ;
			} ;
			exit ;
		}END{
			if( rv == 1 ){
				print "notExecutableScript" ;
			} ;
		}' )

	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t\t testTxt = ${testTxt}" >&2 ; fi ;

	case "${testTxt}" in
		'#!/bin/'* | '#!/usr/'* | '#! /bin/'* | '#! /usr/'* )	;;
			* )	testTxt=""
				testTxt=$(file "${fileA}" | cut -f2 -d: | grep 'ASCII text' )
				if [ -z "${testTxt}" ] ; then 
					testTxt=$(file "${fileA}" | cut -f2 -d: | grep 'Rich Text Format data' )
					if [ -z "${testTxt}" ] ; then 
						#testTxt=$(file "${fileA}" | cut -f2 -d: | grep 'UTF-8 Unicode text' )
						testTxt=$(file "${fileA}" | cut -f2 -d: | grep 'Unicode text' )
						if [ -z "${testTxt}" ] ; then 
							testTxt=$(head -10 "${fileA}" | grep 'Name: ' )
							if [ -n "${testTxt}" ] ; then 
								testTxt="${testTxt} == 2"
							fi
						fi
					fi
				fi
				;;
	esac
	
	echo -e "\t\t\t ### testTxt = '${testTxt}' ..."
	if [ -n "${testTxt}" ]
	then 
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5C] ..." >&2 ; fi ;

		isText=1 ;
       		isBin=0 ;
		echo -e "\t COMPARING:\n\t diff --suppress-common-lines '${fileA}' '${fileB}' >${TMP}.diff ..." 
		diff --suppress-common-lines "${fileA}" "${fileB}" >${TMP}.diff ;
	else
		testImg=$(file "${fileA}" | cut -f2 -d: | grep 'image data' ) ;
		if [ -z "${testImg}" ]
		then
			testImg=$(file "${fileA}" | cut -f2 -d: | grep 'bitmap' ) ;
		fi

		echo -e "\t\t\t ### testImg = '${testImg}' ..." ;
		if [ -n "${testImg}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5A] ..." >&2 ; fi ;

			isImage=1 ;
			diffImg ;
		else
			testVid=$(file "${fileA}" | cut -f2 -d: | grep 'video' ) ;

			echo -e "\t\t\t ### testVid = '${testVid}' ..." ;
			if [ -n "${testVid}" ]
			then
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5B] ..." >&2 ; fi ;

				isVideo=1 ;
				diffVid ;
			else
				testZip=$(file "${fileA}" | cut -f2 -d: | grep 'Zip archive data' ) ;

				echo -e "\t\t\t ### testZip = '${testZip}' ..." ;
				if [ -n "${testZip}" ]
				then
					if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5C] ..." >&2 ; fi ;

					isZip=1 ;
					diffZip ;
				else
					testGzip=$(file "${fileA}" | cut -f2 -d: | grep 'gzip compressed data' ) ;

					echo -e "\t\t\t ### testGzip = '${testGzip}' ..." ;
					if [ -n "${testGzip}" ]
					then
						if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5D] ..." >&2 ; fi ;

						isGzip=1 ;
						diffGzip ;
					else
						testTar=$(file "${fileA}" | cut -f2 -d: | grep 'tar archive' ) ;

						echo -e "\t\t\t ### testTar = '${testTar}' ..." ;
						if [ -n "${testTar}" ]
						then
							if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5E] ..." >&2 ; fi ;

							isTar=1 ;
							diffTar ;
						else
							testBin=$(file "${fileA}" | cut -f2 -d: | grep 'executable' ) ;

							echo -e "\t\t\t ### testBin = '${testBin}' ..." ;
							if [ -n "${testBin}" ]
							then
       								isBin=1 ;
								if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5Zb1] ..." >&2 ; fi ;
							else
								isText=1 ;
       								isBin=0 ;
								if [ ${VERBl} -eq 1 ] ; then  echo -e "\t     [5Zb2] ..." >&2 ; fi ;
							fi

							diffBin ;
						fi
					fi
				fi
			fi
		fi
	fi

}	#diffFile()


#################################################################################################################
#################################################################################################################
fils_NewerInReference()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  fils_NewerInReference() ..." >&2 ; fi

	frame="NewerInReference"

	while read fileB
	do
		echo -e "\t mode= ${mode} ..."
		fileA=$(basename "${file}" )

		if [ ${VERBf} -eq 1 ] ; then  echo -e "\t ------------ \n\t  ${fileB} ..." ; fi

		fileDir=$(dirname "${fileB}" )
		fileBase=$(basename "${fileB}" )

		if [ "${fileBase}" = "${fileA}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA] ..." >&2 ; fi
			
#			if [ ${mode} -eq 1 ]
#			then
				testA=$(stat --format "%y" "${fileA}" )
				testB=$(cd "${fileDir}" ; stat --format "%y" "${fileBase}" )
#			else
#				testC=$(stat --format "%z" "${file}" )
#				testD=$(cd "${fileDir}" ; stat --format "%z" "${fileBase}" )
#			fi

			testE=$(stat --format "%s" "${fileA}" )
			testF=$(cd "${fileDir}" ; stat --format "%s" "${fileBase}" )

			# Level 1
			if [ ${DBGf} -eq 1 ] ; then  echo -e "\t context= ${context}" ; fi

			diffFile

	###
	###	Logid of 'closeMatchDiff' is questionable and needs a review/rewrite
	###
	#		if [ -s ${TMP}.diff ]
	#		then
	#			#if [ \( ${isImage} -ne 1 \) -a \( ${isVideo} -ne 1 \) ]
	#			if [ ${isText} -eq 1 ]
	#			then
	#				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-1] ..." >&2 ; fi
	#
	#				closeMatchDiff
	#			fi
	#		fi

			if [ -s ${TMP}.diff ]
			then
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2a] ..." >&2 ; fi

				if [ ${isImage} -eq 0 ]
				then
					echo -e "\t ============================================================================="
					ls -l ${TMP}.diff | awk '{ printf("\t %s\n", $0 ) }'
				fi

				diffSize=$(wc -l ${TMP}.diff | awk '{ print $1 }' )
				if [ ${diffSize} -gt 200 ]
				then
	###
	###	Logid of 'closeMatchDiff' is questionable and needs a review/rewrite
	###
	#				closeMatchDiff

					if [ -s ${TMP}.diff ]
					then
						if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2a-1a] ..." >&2 ; fi
						echo -e "\n\t *** Difference report too large to allow meaningful quick review for decision ..."
						cat ${TMP}.diff | awk '{ printf("\t\t %s\n", $0 ) ; }'
					else
						if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2a-1b] ..." >&2 ; fi

						reportAndPurge
					fi
				else
					if [ ${isImage} -eq 1 ]
					then
						if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2a-2a] ..." >&2 ; fi
						echo -e "\t IMAGE_DATA - Files not identical. No useful report to view ..."
						cat ${TMP}.diff
					else
						if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2a-2b] ..." >&2 ; fi
						echo ""
						cat ${TMP}.diff | awk '{ printf("\t\t %s\n", $0 ) ; }'
					fi
				fi

				echo ""
				if [ ${DBGf} -eq 1 -a -n "testA" ] ; then  echo -e "\t\t   Current = ${testA}" ; echo -e "\t\t Reference = ${testB}" ; fi
#				if [ ${DBGf} -eq 1 -a -n "testC" ] ; then  echo -e "\t\t testC= ${testC}" ; echo -e "\t\t testD= ${testD}" ; fi
				( ls -ld "./${fileA}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'

				echo -e "\t CANDIDATE_OLDER_VERSION  '${fileA}' ..."

				rm -f ${TMP}.date
				echo -e "${testA}|testA|\n${testB}|testB|" | sort -nr >${TMP}.date
				testorD=$(head -1 ${TMP}.date | grep '|testA|' )

#				if [ "${testA}" -gt "${testB}" -o "${testC}" -gt "${testD}" ]
				if [ -n "${testorD}" ]
				then
					echo -e  "\t\t Modification timestamp conflicts with 'find' results:  rm  -i \"./${fileA}\" <&2 "
					rm  -i "./${fileA}" <&2 | awk '{ printf("\t\t %s\n", $0 ) }'
				else
					echo -e  "\t\t Modification timestamp confirms 'find' results:  rm  -i \"./${fileA}\" <&2 "
					rm  -i "./${fileA}" <&2 | awk '{ printf("\t\t %s\n", $0 ) }'
				fi
			else
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2b] ..." >&2 ; fi

# if mode -eq 2
				reportAndPurge
			fi
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aB] ..." >&2 ; fi

			echo -e "\t BASENAME_MISMATCH (1) '${fileA}' ..."
		fi
	done <${TMP}

	rm -f ${TMP}.diff
}	#fils_NewerInReference()


#################################################################################################################
#################################################################################################################
fils_NewerInCurrent()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  fils_NewerInCurrent() ..." >&2 ; fi

	frame="NewerInCurrent"

	while read fileA
	do
		echo -e "\t mode= ${mode} ..."
		fileA=$(basename "${fileA}" )
		fileB="${GOOD_REFERENCE}/${file}"

		if [ ${VERBf} -eq 1 ] ; then  echo -e "\t ------------ \n\t  ${fileB} ..." ; fi

		fileDir=$(dirname "${fileB}" )
		fileBase=$(basename "${fileB}" )

		if [ "${fileBase}" = "${fileA}" ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4bA] ..." >&2 ; fi

#			if [ ${mode} -eq 1 ]
#			then
				testA=$(stat --format "%y" "${fileA}" )
				testB=$(cd "${fileDir}" ; stat --format "%y" "${fileBase}" )
#			else
#				testC=$(stat --format "%z" "${fileA}" )
#				testD=$(cd "${fileDir}" ; stat --format "%z" "${fileBase}" )
#			fi
			testE=$(stat --format "%s" "${fileA}" )
			testF=$(cd "${fileDir}" ; stat --format "%s" "${fileBase}" )

			# Level 2
			if [ ${DBGf} -eq 1 ] ; then  echo -e "\t context= ${context}" ; fi
if [ ${DBGx} -eq 1 ] ; then  set -x ; fi

			diffFile

	###
	###	Logid of 'closeMatchDiff' is questionable and needs a review/rewrite
	###
	#		if [ -s ${TMP}.diff ]
	#		then
	#			#if [ \( ${isImage} -ne 1 \) -a \( ${isVideo} -ne 1 \) ]
	#			if [ ${isText} -eq 1 ]
	#			then
	#				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-1] ..." >&2 ; fi
	#
	#				closeMatchDiff
	#			fi
	#		fi

			if [ -s ${TMP}.diff ]
			then
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4bA-2a] ..." >&2 ; fi

				if [ ${isImage} -eq 0 ]
				then
					echo -e "\t ============================================================================="
					ls -l ${TMP}.diff | awk '{ printf("\t %s\n", $0 ) }'
				fi

				diffSize=$(wc -l ${TMP}.diff | awk '{ print $1 }' )
				if [ ${diffSize} -gt 200 ]
				then
	###
	###	Logid of 'closeMatchDiff' is questionable and needs a review/rewrite
	###
	#				closeMatchDiff

					if [ -s ${TMP}.diff ]
					then
						if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2a-1a] ..." >&2 ; fi
						echo -e "\n\t *** Difference report too large to allow meaningful quick review for decision ..."
						cat ${TMP}.diff | awk '{ printf("\t\t %s\n", $0 ) ; }'
					else
						if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-2a-1b] ..." >&2 ; fi

						reportAndPurge
					fi
				else
					if [ ${isImage} -eq 1 ]
					then
						echo -e "\t IMAGE_DATA - Files not identical. No useful report to view ..."
						cat ${TMP}.diff
					else
						echo ""
						cat ${TMP}.diff | awk '{ printf("\t\t %s\n", $0 ) ; }'
					fi
				fi

				echo ""
				if [ ${DBGf} -eq 1 -a -n "testA" ] ; then  echo -e "\t\t   Current = ${testA}" ; echo -e "\t\t Reference = ${testB}" ; fi
#				if [ ${DBGf} -eq 1 -a -n "testC" ] ; then  echo -e "\t\t testC= ${testC}" ; echo -e "\t\t testD= ${testD}" ; fi
				( ls -ld "./${fileA}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'

				rm -iv "${fileA}" <&2

				if [ -s "${fileA}" ]
				then
					echo -e "\t RETAIN_NEWER '${fileA}' ..."

					rm -f ${TMP}.date
					echo "${testA}|testA|\n${testB}|testB|" | sort -nr >${TMP}.date
					testorD=$(head -1 ${TMP}.date | grep '|testB|' )

					echo -e  "\t WARNING:  Require visual review to confirm same contextual relevance before clobbering ..."
					echo "${fileA}" >>${TMP}.compare

					if [ -n "${testorD}" ]
					then
						echo -e  "\t\t Modification timestamp conflicts with 'find' results:"
						echo -e  "\t DEFERRED:  cp -p \"${fileA}\" \"${fileB}\" ..."
					else
						echo -e  "\t\t Modification timestamp confirms 'find' results:"
						echo -e  "\t DEFERRED:  cp -p \"${fileA}\" \"${fileB}\" ..."
					fi
				fi
			else
				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4bA-2b] ..." >&2 ; fi

# if mode -eq 4
				reportAndPurge
			fi
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4bB] ..." >&2 ; fi

			echo -e "\t BASENAME_MISMATCH (2) '${fileA}' ..."
		fi
if [ ${DBGx} -eq 1 ] ; then  set +x ; fi
	done <${TMP}

	rm -f ${TMP}.diff
}	#fils_NewerInCurrent()


#################################################################################################################
#################################################################################################################
evaluateFils()
{
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  evaluateFils() ..." >&2 ; fi

	testA=""
	testB=""
	testE=""
	testF=""

	isImage=0
	isVideo=0
	isZip=0
	isGzip=0
	isTar=0
	isText=0

if [ -f "${GOOD_REFERENCE}/${file}" ]
then
	rm -f ${TMP}
	#find "${GOOD_REFERENCE}" -xdev -mindepth 1 \( ! -type d \) -name "${file}" -newer "./${file}" -print >${TMP} 2>>/dev/null
	find "${GOOD_REFERENCE}" -xdev -maxdepth 1 -mindepth 1 \( ! -type d \) -name "${file}" -newer "./${file}" -print >${TMP} 2>>/dev/null

	if [ -s ${TMP} ]
	then
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t   [F3A] ..." >&2 ; fi

		mode=1
		context="NewerInReference"
		fils_NewerInReference
	else
		rm -f ${TMP}
		#find . -xdev -mindepth 1 \( ! -type d \) -name "${file}" \( -newer "${GOOD_REFERENCE}/${file}" \) -print >${TMP} 2>>/dev/null
		find . -xdev -maxdepth 1 -mindepth 1 \( ! -type d \) -name "${file}" \( -newer "${GOOD_REFERENCE}/${file}" \) -print >${TMP} 2>>/dev/null

		if [ -s ${TMP} ]
		then
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t   [F3B] ..." >&2 ; fi

			mode=3
			context="NewerInCurrent"
			fils_NewerInCurrent
		else
			if [ ${VERBl} -eq 1 ] ; then  echo -e "\t   [F3C] ..." >&2 ; fi

			fileA="${file}"
			fileB="${GOOD_REFERENCE}/${file}"

			testA=$(stat --format "%y" "${fileA}" )
			testB=$(cd "${GOOD_REFERENCE}" ; stat --format "%y" "${fileA}" )
			testE=$(stat --format "%s" "${fileA}" )
			testF=$(cd "${GOOD_REFERENCE}" ; stat --format "%s" "${fileA}" )

			if [ "${testA}" = "${testB}" -a "${testE}" = "${testF}" ]
			then
				mode=5
				frame="Same"

				diffFile

		###
		###	Logid of 'closeMatchDiff' is questionable and needs a review/rewrite
		###
		#		if [ -s ${TMP}.diff ]
		#		then
		#			#if [ \( ${isImage} -ne 1 \) -a \( ${isVideo} -ne 1 \) ]
		#			if [ ${isText} -eq 1 ]
		#			then
		#				if [ ${VERBl} -eq 1 ] ; then  echo -e "\t    [4aA-1] ..." >&2 ; fi
		#
		#				closeMatchDiff
		#			fi
		#		fi

				if [ -s ${TMP}.diff ]
				then
					echo -e "\t\t WARNING:  Unanticipated condition encountered. No action taken ..."
					###  UNDER_REVIEW  ###  compareLineByLineCharacterDiff.sh --lineNum --fileCur "${fileA}" --fileRef "${fileB}"
					( ls -ld "./${fileA}" ; ls -ld "${fileB}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
				else
					#echo -e "\t MATCH (2) '${fileA}' ... (Action TBD)"
					context="Identical"
					reportAndPurge
				fi
			fi

#			##################################################################################
#			##################################################################################
#			###	OLD LOGIC
#			##################################################################################
#			##################################################################################
#
#			rm -f ${TMP}
#			find "${GOOD_REFERENCE}" \( ! -type d \) -name "${file}" -cnewer "./${file}" -print >${TMP} 2>>/dev/null
#
#			if [ -s ${TMP} ]
#			then
#				mode=2
#				fils_NewerInReference
#			else
#				rm -f ${TMP}
#				find . \( ! -type d \) -name "${file}" \( -cnewer "${GOOD_REFERENCE}/${file}" \) -print >${TMP} 2>>/dev/null
#
#				if [ -s ${TMP} ]
#				then
#					mode=4
#					fils_NewerInCurrent
#				else
#					echo -e "\t NO_MATCH (2) '${file}' ..."
#				fi
#			fi
#
#			##################################################################################
#			##################################################################################
#			##################################################################################
		fi
	fi
else
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t   [F3D] ..." >&2 ; fi

	echo -e "\t NO_MATCH (2) '${file}' ..."
fi
}	#evaluateFils()


#################################################################################################################
#################################################################################################################
scanLibsLoop()
{
	#FUTURES:  Loop scan of only directories, choose deepest directory, process that before handling upper levels.
	#          Compare that directory with corresponding directory, if it exists.

	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t\t in  scanLibsLoop() ..." >&2 ; fi

	doSkip=0

	if [ "${StartDIR}" = "${CodeROOT}/${dREF}" ]
	then
		doSkip=1
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t  [2A] ..." >&2 ; fi

		echo -e "\t *** SKIPPING ***  '${CodeROOT}/${dREF}' is same as start directory for comparison ...\n"
	else
		if [ ${VERBl} -eq 1 ] ; then  echo -e "\t  [2B] ..." >&2 ; fi

		GOOD_REFERENCE="${CodeROOT}/${dREF}"

		rm -f ${TMP}.dirlist
		ls -a | tail -n +3  >${TMP}.dirlist

		if [ -s ${TMP}.dirlist ]
		then
			doSkip=0
			echo -e "\n #########################################################################################"
			echo -e " #########################################################################################"
			echo -e "	Doing scan loop on contents of LIBRARY \n\t => '${CodeROOT}/${dREF}' ...\n"

			echo -e "\n\t Starting sequence to purge from current directory ..."

			#cat ${TMP}.dirlist
			#exit 1

			while read file
			do
				if [ ${VERBf} -eq 1 ] ; then  echo -e "\n============== \n WORKING:  |${file}| ..." ; fi

				if [ -d "${file}" ]
				then
					if [ ${VERBl} -eq 1 ] ; then  echo -e "\t  [2B-1] ..." >&2 ; fi

					if [ -d "${GOOD_REFERENCE}/${file}" ]
					then
						echo -e "\n\t DIRECTORY__COMPARISON:"
						#echo -e "\n\t NOTICE:  Automated evaluation of directories has been suppressed until more robust logic can be defined ..."

						#dummyHidden()
						evaluateDirs

					else
						echo -e "\n\t DIRECTORY__NoEquiv|${file}"
					fi
				else
					case "${file}" in
						*.tar.contents | *.tar.err | *.tar.log | *.tar.errlog | *.tar.logerr | *.tar.list | *.tar.recurse )
							Tsuf=$(echo "${file}" | awk '{ n=split($0,var,".") ; print var[n] }' )
							baseThisFile=$(basename "${file}" ".${Tsuf}" )
							if [ ! -f "${baseThisFile}" -a ! -f "${baseThisFile}.gz" ]
							then
								rm -f "${file}"
								echo -e "\t\t Purged defunct contents list:  '${file}' ..."
							fi
							;;
						* )
							if [ ${VERBl} -eq 1 ] ; then  echo -e "\t  [2B-1] ..." >&2 ; fi
							evaluateFils
							;;
					esac
				fi

				if [ ${DBGf} -eq 1 ] ; then  break ; fi
			done <${TMP}.dirlist

			doGzipR=0
			rm -f ${TMP}.gzip
			ls *.gz >${TMP}.gzip 2>>/dev/null

			if [ -s ${TMP}.gzip ]
			then
				if [ -f ${TMP}.gzip.first ]
				then
					### logic to clean up for change of startDIR
					read gzipReference <${TMP}.gzip.first
					if [ "${gzipReference}" != "${StartDIR}|${GOOD_REFERENCE}" ]
					then
						rm -f ${TMP}.gzip.first
					fi
				fi

				if [ -f ${TMP}.gzip.first ]
				then
					read gzipReference <${TMP}.gzip.first
					if [ "${gzipReference}" = "${StartDIR}|${GOOD_REFERENCE}" ]
					then
						doGzipR=1
					#else
					#	rm -f ${TMP}.gzip.first
					fi
				else

				#if [ -s ${TMP}.gzip ]
				#then
					echo -e "\t Cycling 'gunzip' and 'gzip' on GZIP files in current directory for later rescan and possible match detection ..."
					while read zipped
					do
						echo -e "\t\t Cycling on '${zipped}' ..."
						base=$(basename "${zipped}" ".gz" )
						#gunzip --verbose "${zipped}"
						gunzip "${zipped}"

						#gzip --verbose "${base}"
						gzip "${base}"
					done <${TMP}.gzip
				fi

				echo "${StartDIR}|${GOOD_REFERENCE}" >${TMP}.gzip.first

				(	
				cd "${GOOD_REFERENCE}"
				if [ $? -eq 0 -a ${doGzipR} -eq 1 ]
				then
					rm -f ${TMP}.R.gzip

					while read zippedC
					do
						if [ -s "${zippedC}" ]
						then
							echo -e "${zippedC}"
						fi
					done <${TMP}.gzip >${TMP}.R.gzip

					if [ -s ${TMP}.R.gzip ]
					then
						echo -e "\t Cycling 'gunzip' and 'gzip' on GZIP files in REFERENCE directory for later rescan and possible match detection ..."
						while read zipped
						do
							echo -e "\t\t Cycling on '${zipped}' ..."
							base=$(basename "${zipped}" ".gz" )
							#gunzip --verbose "${zipped}"
							gunzip "${zipped}"

							#gzip --verbose "${base}"
							gzip "${base}"
						done <${TMP}.R.gzip
					fi
				fi
				)
			fi
		else
			doSkip=1
			echo -e "\n\n\t ** No files remaining in start directory.  ABANDONING ..."
		fi

	fi
}	#scanLibsLoop()


#################################################################################################################
#################################################################################################################
###
###			MAIN PROGRAM
###
#################################################################################################################
#################################################################################################################

IDIFF=$(which idiff )
if [ -z "${IDIFF}" ]
then
	echo -e "\n\t WARNING:  unable to locate required utility 'idiff'.  This will impact comparison of images ..."
fi


rm -f pspbrwse.jbf Thumbs.db

doAllBins=0

while [ $# -gt 0 ]
do
	case $1 in
		--batchAll )
			doAllBins=1 ; shift 
			;;
		--reference )
			if [ -z "${2}" ] ; then  echo -e "\n\t\t NULL ENTRY => Process abandoned. \n\n Bye!\n" ; exit 0 ; fi
			fullPathToReference="${2}" ; shift ; shift
			CodeROOT=$(dirname "${fullPathToReference}" )
			dREF=$(basename "${fullPathToReference}" )
			;;
		--prompt )
			shift
			# Reference directory is not under local code library directory "LO"
			promptForReferencePath
			;;
		#--items_d )
		#	VERBd=1 ; shift ;;
		#--items_f )
		#	VERBf=1 ; shift ;;
		--trace )
			VERBl=1 ; shift ;;
		* ) echo -e "\n\t Invalid parameter used on the command line.  Unable to proceed.\n Bye!\n" ; exit 1
			;;
	esac
done


if [ ${doAllBins} -eq 1 ]
then
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t [1A] ..." >&2 ; fi

	#for dREF in bin_Admin bin_Dev bin_Eval bin_FW bin_OS bin_User bin_Util bin_Sec
	for dREF in $(cd "${CodeROOT}" ; ls )
	do
		if [ -d "${CodeROOT}/${dREF}" ]
		then
			scanLibsLoop
		else
			echo -e "\n\t *** SKIPPING ***  '${CodeROOT}/${dREF}' is not a directory ..."
		fi
	done
else
	if [ ${VERBl} -eq 1 ] ; then  echo -e "\t [1B] ..." >&2 ; fi

	#echo -e "\t REF = ${fullPathToReference}   (before test)" >&2

	if [ -z "${fullPathToReference}" ]
	then
		while true
		do
			selectOneOf
			test ${doBreak} -eq 1 && break ;
		done
	fi

	scanLibsLoop
fi
	
echo -e "\n#############################################################################\n\n Phase I  - Confirmed Duplicates Purged."

#################################################################################################################
#################################################################################################################

cd "${StartDIR}"

#################################################################################################################

rm -f ${TMP}
rm -f ${TMP}.remainder

find . -xdev -maxdepth 1 -mindepth 1 -print | sed 's+^\./++' | sort -r >${TMP}.remainder 2>>/dev/null

if [ -s ${TMP}.remainder ]
then
  if [ ${doSkip} -eq 1 ]
  then
	#echo -e "\n Phase II - No files retained for reclaim.\n Done!\n"
	echo -e "\n Phase II - Directed to skip this reclaim step.\n Done!\n"
  else
	echo -e "\n Phase II - Integration of Retained Files ..."

	#FUTURES - add logic to move items from current directory to replace those in Library if newer and preferred.

	echo -e "\n\t Move retained/preferred version of files to reference library. \n\t Continue ?  [y|N] => \c"

	selectYesNo

    if [ $? -eq 0 ]
    then
	echo -e "\n\t Cleanup DEFERRED.\n Done!\n"
    else
	echo -e "\n\t Creating batch instructions for file reclaim/retention ..."

	#cat "${TMP}.remainder"

	#for file in *
	while read file
	do
		if [ -d "./${file}" ]
		then
			echo -e "\n\t DIRECTORY - deferred  './${file}' ..."
			ls -ld "./${file}" 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
			echo -e "#[DIRECTORY__REVIEW_LOWER_LEVELS] |'./${file}' " | tee --append "${DEFERRED}" 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
		else
			if [ -s "${GOOD_REFERENCE}/${file}" ]
			then
				rm -f ${TMP}
				find . -xdev -maxdepth 1 -mindepth 1 \( ! -type d \) -name "${file}" \( -newer "${GOOD_REFERENCE}/${file}" \) -print >${TMP} 2>>/dev/null

				if [ -s ${TMP} ]
				then
					echo -e "\n\t FILE:  './${file}' ..."
					tester=$(wc -l ${TMP} | awk '{ print $1 }' )
					if [ $tester -gt  1  ]
					then
						echo -e "\n [UNKNOWN CONDITION - MULTIPLE FILES] ..."
						ls -ld $(cat ${TMP} )  2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
						echo -e "[DEFERRED - FURTHER EVAL REQUIRED] |'./${file}'\n" 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
					else
						( ls -ld "./${file}" ; ls -ld "${GOOD_REFERENCE}/${file}" ) 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
						testorC=$( grep "^${file}\$" ${TMP}.compare ) 
						if [ -n "${testorC}" ]
						then
							echo -e "#RECONFIRM DETERMINATION# |mv -fv './${file}' '${GOOD_REFERENCE}/${file}'" | tee --append "${DEFERRED}" 2>&1 | awk '{ printf("\t\t [WITHELD - REPLACE]  |%s\n", $0 ) }'
						else
							echo -e "mv -fv './${file}' '${GOOD_REFERENCE}/${file}'" | tee --append "${DEFERRED}" 2>&1 | awk '{ printf("\t\t [WITHELD - REPLACE]  |%s\n", $0 ) }'
						fi
					fi
				fi
			else
				echo -e "\n\t NO MATCH IN REFERENCE - './${file}' ..."
				ls -ld "./${file}" 2>&1 | awk '{ printf("\t\t %s\n", $0 ) }'
				echo -e "mv -fv './${file}' '${GOOD_REFERENCE}/${file}'" | tee --append "${DEFERRED}" 2>&1 | awk '{ printf("\t\t [WITHELD - NO MATCH]  |%s\n", $0 ) }'
			fi
		fi
	done <${TMP}.remainder

	if [ -s "${DEFERRED}" ]
	then
		echo -e "\n\t TODO - 'Batch Action' file:   (review to apply indicated actions)"
		ls -l "${DEFERRED}" | awk '{ printf("\t\t %s\n", $0 ) }'
	fi

	echo -e "\n Done!\n"
    fi
  fi
else
	echo -e "\n Phase II - No files retained for reclaim.\n Done!\n"
fi

rm -f ${TMP}



exit 0
exit 0
exit 0




#FUTURES - add logic to look for match on stat report using 1) date, 2) file size and 3) file type ... to locate possibly renamed file containing identical coding.


