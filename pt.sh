#!/bin/sh
# Name: $Id: pt.sh,v 2.1 2020/10/20 21:11:24 root Exp $
# Desc: Script to print a process tree on stdout.
#	- easy to see relationships between processes with this script
# Synt: pt [opts] [startPID]
# Opts:	-h,H,-V	: help,HELP,version
#	-w width: screen width
#	-o type	: output type: 1, 2, or 3 (def 3)
# Parm: startPID: show tree starting at this PID (def: 1)

# @(#) pt - display Process Table "Tree"
#
# Original Author:  William J. Duncan (prior to May 7 1996)
#
# Synopsis:
#   pt [opts] [startPID] |  less      # (or whatever your fav pager is)
#
# Notes:
#   - all recent implementations of awk I have seen have recursion.
#     It is a requirement.  This is a nice little example of using
#     recursion in awk.
#
#   - under bsd, there was no real happy mix of options which
#     would pick up a user's name, and do everything else we wanted.
#     (eg. need to pick up PPID for example)
#     So we need to do a separate search through the passwd entries
#     ourselves and build a lookup table, or alternatively run ps
#     twice.
#
#   - notice the ugliness of 3 separate sets of quotes required in
#     the line:
#       while ("'"$GETPASSWD"'" | getline > 0)
#
#     The inside pair of quotes keeps the 2 tokens for the command
#     together.  The pair of single quotes escapes from within the
#     awk script to the "outside" which is the shell script.  This
#     makes the shell variable "$GETPASSWD" available for use with-
#     in the awk script as a literal string.  (Which is the reason
#     for the outside pair of double quotes.)
#
#   - This is the general format of including awk scripts within
#     the shell, and passing ENVIRONMENT variables down.    -wjd
#
##################################################################################
#
# Mods by E. Marceau, Ottawa, Canada
#
#   - Added logic to determine max length of username for proper display of that field
#
##################################################################################
#
##################################################################################

TMP=/tmp/`basename "$0" ".sh" `.$$

set -u
## Constants
  rcsid='$Id: pt.sh,v 2.1 2020/10/20 21:11:24 root Exp $'
  P=`basename $0`;
  ## This command should list the password file on on "all" systems, even
  ## if YP is not running or 'ypcat' does not exist.
  ## List the local password file first because the UIDS array is assigned
  ## such that later entries override earlier entries.

  if [ -z "`which ypcat 2>>/dev/null `" ]
  then
     GETPASSWD="(cat /etc/passwd)"
  else
     GETPASSWD="(ypcat passwd 2>/dev/null)"
  fi

## Name: usage;   Desc: standard usage description function
   usage() { awk 'NF==0{if(n++=='${1:-0}')exit}0==0'<$0; }

maxWidth=0

## check for options
   set -- `getopt ehHVw:o: ${*:-}`
   test $? -ne 0  &&  usage 0  &&  exit 9
   for i in $*; do
        case $i in
        -e)     maxWidth=1    ;  COLS=512 ; shift	;;
        -h)     usage 0 && exit 9                       ;;
        -H)     usage 1 && exit 9                       ;;
	-V)	echo "${P} ${rcsid}"|cut -d' ' -f1,4-5; exit;;
	-w)	COLS=$2       ;  shift 2		;;
	-o)     outtype=$2    ;  shift 2		;;
        --)     shift         ;  break			;;
        esac
   done

## initialize
   startpid="${1:-1}"
   SYSTEM=${SYSTEM:-`uname`}
   outtype="${outtype:-3}"

case ${SYSTEM} in
	#    XENIX)          # or any other sys5 i think
	#        PS=/bin/ps
	#        AWK=/bin/awk
	#        PSFLAGS=-ef
	#        SYSTEM=sys5
	#        SIZE='/bin/stty size'
	#        ;;
	#    SunOS)          # bsd flavours of ps
	#        os=`uname -r | cut -c1`
	#        PS=/bin/ps
	#        AWK=nawk
	#	if test "$os" = "4"; then
	#           PSFLAGS=-axjww
	#           SYSTEM=bsd
	#           SIZE='/bin/stty size'
	#	else
	#           PSFLAGS=-ef
	#           SYSTEM=sys5
	#           SIZE='/usr/ucb/stty size'
	#	fi
	#	;;
	#    HP-UX)
	#        PS=/bin/ps
	#    	AWK=/usr/bin/awk
	#        PSFLAGS=-ef
	#        SYSTEM=sys5
	#        SIZE='/bin/stty size'
	#        ;;
    Linux)
        PS=/bin/ps
        AWK=awk
        PSFLAGS=-axjww
        SYSTEM=bsd
        SIZE='/bin/stty size'
	;;
    *)
        PS=/bin/ps
        AWK=awk
        PSFLAGS=-axjww
        SYSTEM=bsd
        SIZE='/bin/stty size'
        ;;
esac

COLShere=`${SIZE} | awk '{print $2}' `
COLS=${COLS:-$COLShere}
COLS=${COLS:-80}

echo "\t	[1] ${COLS}"

${PS} ${PSFLAGS} | 
${AWK} -v maxWidth="${maxWidth}" 'BEGIN{  lowestPID=9999 ;
		FS = ":" ;
		while ("'"${GETPASSWD}"'" | getline > 0){
			UIDS[ $3 ] = $1 ;
		} ;
		UIDS[ 0 ] = "root" ;				# fix for "extra" root accounts

		for ( var in UIDS ){
			lenT=length( UIDS[var] ) ;
			if ( lenT > lenM ){
				lenM=lenT ;			# longest=UIDS[var] ;
			} ;
		} ;

		printf("%6s %6s %4s  %-"lenM"s %s\n", "PID", "PPID", "TTY", "USER", "COMMAND" ) ;

		FS = " " ;
		COLS='${COLS}' ;
		SYSTEM="'${SYSTEM}'" ;

		if (SYSTEM == "sys5"){
			fpid   = 2 ;
			fppid  = 3 ;
			fuid   = 1 ;
		}else{
			if (SYSTEM == "bsd"){
				fpid   = 2 ;
				fppid  = 1 ;
				fuid   = 8 ;
			} ;
		} ;

		outtype ="'${outtype}'" ;

		if (outtype == 1){
			SPACES=".............................................................................................." ;
			SPREAD=1 ;
			CMD_PREFIX=" " ;
		}else{
			if (outtype == 2){
				SPACES="||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||" ;
				SPREAD=1 ;
				CMD_PREFIX="" ;
			}else{
				SPACES="| | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |" ;
				SPREAD=2 ;
				CMD_PREFIX="" ;
			} ;
		} ;
	
	} ;


	NR==1 { title = $0 ; next } ;

	# All others
	{
		if ( $fpid < lowestPID ){ lowestPID=$fpid ; } ;
		LINE[ $fpid  ] = $0  ;                    	# Line indexed by PID
		PCNT[ $fppid ]++  ;                       	# Index into PPID
		PPID[ $fppid, PCNT[$fppid] ] = $2 ;       	# Parent to Children unique

		INDENT=0 ;
	} ;

	function doprint(s, a, name, i, nf, tty, cmd){
		# the splitting and complications here are mostly for
		# sys5, which a different number of fields depending on STIME
		# field.  Argh.
		nf = split(s,a) ;
		for (i=7; i <= nf; i++){
		       	if (a[i] ~ /[0-9]:[0-9][0-9]/){
				break   # set i here
			} ;
		} ;

		for (i++ ; i <= nf; i++){
			name = name " " a[i] ;
		} ;

		if (a[fuid] in UIDS){
			a[fuid] = UIDS[a[fuid]] ;             # if username found
		} ;

		if (SYSTEM == "bsd"){                    # if bsd
			tty = a[5] ;
		}else{                                    # sys5 2 possible formats
			tty = (a[5] ~ /^[0-9]+:/) ? a[6] : a[7] ;
		} ;

		cmd = substr(SPACES,1,INDENT*SPREAD) CMD_PREFIX substr(name,2) ;

		#if ( length(cmd) > COLS-27 && maxWidth == 0 ){
		if ( length(cmd) > COLS-27 ){
			cmd = substr(cmd,1,COLS-27) ;
		} ;

		printf("%6d %6d %4s  %-"lenM"s %s\n", a[fpid], a[fppid], substr(tty,length(tty)-1), a[fuid], cmd ) ;
	} ;

	function dotree(pid) {      # recursive
		if (pid == 0) return

		doprint(LINE[ pid ])
		INDENT++
		while (PCNT[pid] > 0) {
			dotree(PPID[ pid, PCNT[pid] ] ) ;	# recurse
			delete PPID[ pid, PCNT[pid] ] ;
			PCNT[pid]-- ;
		} ;
		INDENT-- ;
	} ;

	END{
		if ( lowestPID > startpid ){ startpid=lowestPID ; } ;
		dotree('${startpid}') ;
	}' >${TMP}.initial


###########################################################################################################################
###
###	Additional coding to present results with PID correctly sorted along with associated children also in sorted order.
###
###########################################################################################################################

head -1 ${TMP}.initial >${TMP}.head
tail --lines=+2 ${TMP}.initial | sort --key=1,1n --key=2,2n >${TMP}.remainder

cat ${TMP}.head

while [ true ]
do
        line=`awk '{ if ( NR == 1 ){ print $0 } ; exit }' <${TMP}.remainder `
        first=`echo "${line}" | awk '{ print $1 }' `
        echo "${line}"

        #get children
        tail --lines=+2 ${TMP}.remainder | awk -v pid="${first}" '{ if ( $2 == pid ){ print $0 } ; }' >${TMP}.next
        tail --lines=+2 ${TMP}.remainder | awk -v pid="${first}" '{ if ( $2 != pid ){ print $0 } ; }' >${TMP}.others

        cat ${TMP}.next ${TMP}.others >${TMP}.remainder

        if [ ! -s ${TMP}.remainder ] ; then  break ; fi
done		###  >${TMP}.new ;cat ${TMP}.new


exit 0
exit 0
exit 0
