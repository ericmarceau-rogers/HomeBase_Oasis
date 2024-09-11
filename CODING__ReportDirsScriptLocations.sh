#!/bin/sh

##############################################################################################
###
###	$Id: CODING__ReportDirsScriptLocations.sh,v 1.1 2024/09/11 18:35:11 root Exp $
###
###	Report list of directories where system-oriented scripts can be found,
###	having the filename form  *.sh, *.bash, *.ash, *.ksh, *.zsh, *.csh
###
##############################################################################################

BASE=`basename "$0" ".sh" `
START=`pwd`

FILES="${START}/${BASE}.files"
DIRS="${START}/${BASE}.dirs"

rm -f ${FILES}
rm -f ${DIRS}

INDEX="${index:-/DB001_F2/LO_Index}"

cd ${INDEX}

grep -v '^/usr' INDEX.allDrives.f.txt |
	grep -v '[a-zA-Z0-9]/OasisMega1.UPDATE/' |
	grep -v '[a-zA-Z0-9]/OasisMega1.DISTRO/' |
	grep -v '[a-zA-Z0-9]/OasisMega2.UPDATE/' |
	grep -v '[a-zA-Z0-9]/OasisMega2.DISTRO/' |
	grep -v '[a-zA-Z0-9]/OasisMidi.UPDATE/' |
	grep -v '[a-zA-Z0-9]/OasisMidi.DISTRO/' |
	grep -v '[a-zA-Z0-9]/OasisMini.UPDATE/' |
	grep -v '[a-zA-Z0-9]/OasisMini.DISTRO/' |
	grep -v '[a-zA-Z0-9]/usr/src/linux-' |
	grep -v '[a-zA-Z0-9]/usr/share/' |
	grep -v '[a-zA-Z0-9]/usr/lib/' |
	grep -v '^/bin' |
	grep -v '^/var' |
	grep -v '^/etc' |
	grep -v '^/lib' |
	grep -v '^/sys' |
	grep -v '^/srv' |
	grep -v '^/run' |
	grep -v '^/opt' |
	grep -v '^/sbin' |
	grep -v '^/proc' |
	grep -v '^/snap' |
	grep -v '^/boot' |
	grep -v '^/local' |
	grep -v '^/mount' |
	grep -v '^/media' |
	grep -v '^/local' |
	grep -v '^/Local' |
	grep -v '^/cdrom' |
	grep -v '^/debian' |
	grep -v '^/CloneBackup' > "${FILES}.tmp"
	grep '\.sh$'   "${FILES}.tmp" >"${FILES}"
	grep '\.bash$' "${FILES}.tmp" >>"${FILES}"
	grep '\.ash$'  "${FILES}.tmp" >>"${FILES}"
	grep '\.ksh$'  "${FILES}.tmp" >>"${FILES}"
	grep '\.zsh$'  "${FILES}.tmp" >>"${FILES}"
	grep '\.csh$'  "${FILES}.tmp" >>"${FILES}"

	cat ${FILES} |
	awk -F/ '{
		if( index( $NF, ":" ) != 1 ){
			for( i=1 ; i <= NF-1 ; i++){
				printf("%s/", $i ) ;
			} ;
			print "" ;
		} ;
	}' |
	sort -r |
	uniq |
	awk '{ if( $1 != "/" ){ print $0 } ; }' >${DIRS}

wc -l ${FILES} ${DIRS}

exit 0
exit 0
exit 0

