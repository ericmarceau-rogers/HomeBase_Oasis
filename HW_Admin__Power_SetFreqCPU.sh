#!/bin/bash

####################################################################################################
###
###	Script to make it easier to learn how to control the CPU 'governor' and CPU clock frequencies
###
###	2024-11-18  --  Version 5.1  --  Eric Marceau, Ottawa, Ontario, Canada
###
### Related discussion:  https://ubuntu-mate.community/t/setting-up-boot-time-service-for-local-custom-cpu-frequency-governor-script-cpupower/28349
###
####################################################################################################
#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+

dbg=0
test "${1}" = "--debug1" && { dbg=1 ; shift ; }
test "${1}" = "--debug2" && { dbg=2 ; shift ; }

###
###	Edit this script to assign preset defaults appropriate for your local Desktop CPU
###
doMode=59	# userspace
doFreq=2	# 1900MHz
doDefault=0
doStatus=0
doCron=0
doService=0

shopt -s extglob

identifyGovernors()
{
	test ${dbg} -gt 0 && echo "	>>> ENTERING identifyGovernors ..." >&2

	#governors=$(echo "userspace performance ondemand conservative powersave schedutil junker" |
	governors=$(grep 'available cpufreq governors:' ${tmp} | 
		sed 's+\:\ +\:+' |
		cut -f2 -d":"    |
		awk -v dbg="${dbg}" 'BEGIN{
			split("", plist) ;

			plist[1,1]="userspace";
			plist[2,1]="performance";
			plist[3,1]="ondemand";
			plist[4,1]="conservative";
			plist[5,1]="powersave";
			plist[6,1]="schedutil";
			c=6 ;

			for( i=1 ; i <= c ; i++ ){
				plist[i,2]=0 ;
			} ;

			if( dbg == 2 ){
				for( j=1 ; j <= c ; j++ ){
					printf("plist[%s] = %s\n", j, plist[j,1] ) | "cat 1>&2" ;
				} ;
			} ;
		}{
			for( k=1 ; k <= NF ; k++ ){
				if( dbg == 2 ){ printf("\t $%d = %s\n", k, $k ) | "cat 1>&2" ; } ; 

				valid=0 ;
				for( m=1 ; m <= c ; m++ ){
					if( dbg == 2 ){ printf("\t\t plist[%d,1] = %s\n", m, plist[m,1] ) | "cat 1>&2" ; } ; 

					if( $k == plist[m,1] ){
						plist[m,2]=1
						valid=1
						break ;
					} ;
				} ;

				if( valid == 0 ){
					printf("\n NOTE:  Reported governor mode \"%s\" is not currently handled by programmed logic.\n", $k ) | "cat 1>&2" ;
				} ;
			} ;
		}END{
			for( n=1 ; n <= c ; n++ ){
				if( plist[n,2] == 1 ){
					printf("%s\n", plist[n,1] ) ;
				} ;
			} ;
		}'
	)
}


getGov()
{
	test ${dbg} -gt 0 && echo "	>>> ENTERING getGov ..." >&2

	case ${doMode} in
		 1 ) governor="performance"	;;
		 2 ) governor="conservative"	;;
		 3 ) governor="powersave"	;;
		 4 ) governor="ondemand"	;;
		 5 ) governor="schedutil"	;;
		58 ) ;;				### governor specified on command line
		59 ) governor="userspace"	;;
	esac
}


identifyFrequencies()
{
	test ${dbg} -gt 0 && echo "	>>> ENTERING identifyFrequencies ..." >&2

	steps=$(grep 'Pstate-' ${tmp} | 
		sed 's+\:\ \ +\:+' |
		cut -f2 -d":"    |
		awk '{
			n=split($0, vals, ",") ;
			for( i=1 ; i <= n ; i++ ){
				printf("%s\n", vals[i] ) ;
			} ;
		}'
	)
}

getFreq()
{
	test ${dbg} -gt 0 && echo "	>>> ENTERING getFreq ..." >&2

	case ${doMode} in
		[1-5] ) return ;;	### No need to so set frequency for these modes
		* ) ;;
	esac

	fmax=$(echo "${steps}" | head -1 )
	fmidhi=$(echo "${steps}" | head -2 | tail -1 )
	fmidlo=$(echo "${steps}" | tail -2 | head -1 )
	fmin=$(echo "${steps}" | tail -1 )

	test -n "${fmin}" || fmin=$(echo "${steps}" | tail -2 | head -1 )

	fopt=( $(echo ${steps} ) )
	len=${#fopt[*]}
	test ${dbg} -gt 0 && echo -e "\n Number of clock speeds identified: ${len}" >&2


	test ${dbg} -gt 1 && echo "doFreq = ${doFreq}" >&2
	case ${doFreq} in
		#(!+[0-9]) ) frequency="NULL" ;;
		80 )
			case "${frequency}" in
				+([0-9])"MHz" ) ;;
				#[0-9]"."+([0-9])"GHz" | [0-9]"."[0-9][0-9]"GHz" )
				[0-9]"."+([0-9])"GHz" )
					fval=$(echo "${frequency}" | sed 's+GHz++' )
					#fval=$(echo "scale=0 ; 1000 * ${fval}" | bc )		### This form doesn't work
					#fval=$(echo "1000 * ${fval}" | bc | cut -f1 -d\. )	### Kludgy fix
					fval=$(echo "1000 * ${fval}" / 1 | bc )			### Elegant fix
					frequency="${fval}MHz"
					;;
			esac
			return ;;
		96 )	frequency="${fmin}" ; return ;;
		97 )	frequency="${fmidlo}" ; return ;;
		98 )	frequency="${fmidhi}" ; return ;;
		99 )	frequency="${fmax}" ; return ;;
		+([0-9]) )
			test ${doFreq} -gt ${len} && { printf "\n\t ERROR:  User has specified frequncy index which is out of range.  Max positional choices = 4.\n Bye!\n\n" ; exit 1 ; }
			frequency="${fopt[$(expr ${doFreq} - 1)]}" ; return ;;
		#'([:alpha:])' )
		* ) printf "\n\t ERROR:  User has specified frequency index which is invalid.  Re-run with no options to obtain report of choices available.\n Bye!\n\n" ; exit 1 ;;
	esac
}


reportOptions()
{
	test ${dbg} -gt 0 && echo "	>>> ENTERING reportOptions ..." >&2

	printf "\n Choices Available for 'CPU Frequency Governor' labels:\n\n"
	echo "${governors}" | awk '{ printf("\t %s\n", $0 ); }'

	printf "\n Choices Available for 'userspace' fixed CPU 'frequency':\n\n"
	echo "${steps}" | awk '{ printf("\t %7s\n", $0 ); }'

	printf "\n Syntax:  $(basename $0 )\n\
		\t\t[\t--list    |\n\
		\t\t\t--detail  |\n\
		\t\t\t--default |\n\
		\t\t\t[ --mode {governor_label} |\n\
		\t\t\t  --max                   |\n\
		\t\t\t  --min                   |\n\
		\t\t\t  --laptop                |\n\
		\t\t\t  --load                  |\n\
		\t\t\t  --adaptive                ]\n\
		\t\t\t[ --freq {frequency} ]\n\
		\t\t]\n\n"


	printf "\n View detailed report generated by 'cpupower' ? [y/N] => " ; read ans ; test -n "$ans" || ans="N"
	case "${ans}" in
		y* | Y* )
			printf "\n Contents of raw report from 'cpupower' (${tmp}):\n\n"
			awk '{ printf("\t|%s\n", $0 ) ; }' <"${tmp}"
			echo ""
			ls -l "${tmp}"
			echo ""
			rm -i "${tmp}"
			;;
		* ) rm -f "${tmp}" ;;
	esac
}


setGovernor()
{
	test ${dbg} -gt 0 && echo "	>>> ENTERING setGovernor ..." >&2

	test -n "${governor}" || { printf "\n ERROR:  No 'governor' label specified.  Unable to proceed.\n\n" ; exit 1 ; }

	#testor=$(grep 'available cpufreq governors:' ${tmp} | grep "${governor}" )
	testor=$(echo "${governors}" | grep "${governor}" )

	test -n "${testor}" || { printf "\n ERROR:  Governor '${governor}' is available for your hardware. Unable to proceed.\n\n" ; exit 1 ; } 

	###	Set CPU frequency under USER-defined control
	COM="${command} --cpu 'all' frequency-set --governor '${governor}'"
	printf "\n COMMAND:  ${COM}\n"
	eval ${COM}
}


setFrequency()
{
	test ${dbg} -gt 0 && echo "	>>> ENTERING setFrequency ..." >&2

	test -n "${frequency}" || { printf "\n ERROR:  No CPU frequency value specified.  Unable to proceed.\n\n" ; exit 1 ; }

	testor=$(grep 'Pstate-' ${tmp} | grep "${frequency}" )

	test -n "${testor}" || { printf "\n ERROR:  Frequency '${frequency}' is not available for your hardware. Unable to proceed.\n\n" ; exit 1 ; } 

	###	Can ONLY set frequency by itself; no other parameters allowed
	COM="${command} --cpu 'all' frequency-set --freq '${frequency}'"
	printf "\n COMMAND:  ${COM}\n"
	eval ${COM}
}


reportStatus()
{
	now=$( date '+%Y-%m-%d %H:%M:%S' )
	for cpu in 0 1 2 3
	do
		fmax=$(cat /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_max_freq )
		fmin=$(cat /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_min_freq )

		govr=$(cat /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_governor )
		freq=$(cat /sys/devices/system/cpu/cpu${cpu}/cpufreq/scaling_cur_freq )

		printf "${now}|  CPU ${cpu}:  %s  %4s MHz [%s <-> %s]\n"  ${govr}  $( expr ${freq} / 1000 )  $( expr ${fmin} / 1000 )  $( expr ${fmax} / 1000 )  
	done
}



command=$(which "cpupower" )
test -n "${command}" || { printf "\n ERROR: Unable to locate command 'cpupower'.  Unable to proceed.\n\n" ; exit 1 ; } 


tmp=/tmp/$(basename "$0" ".sh" ).report


### get details report to parse for available governor labels and CPU frequencies
${command} frequency-info --debug >${tmp}

test -s "${tmp}" || { printf "\n ERROR: ${command} did not generate the required details report.  Unable to proceed.\n\n" ; exit 1 ; }


identifyGovernors

identifyFrequencies


test ${dbg} -gt 0 && echo "	>>> START parsing ..." >&2

### always report safely and informatively, if no parameters provided
if [ $# -eq 0 ]
then
	set - '--list'
fi

while [ $# -gt 0 ]
do
	case "${1}" in
		"--list" )
			reportOptions ; echo "" ; exit 0 ; ;;
		"--detail" )
			${command} frequency-info --debug ; echo "" ; exit 0 ;;
		"--mode" )
			doMode=58 ;
			governor="${2}" ; shift ; shift ;;
		"--max" )
			doMode=1 ; shift ;;
		"--min" )
			doMode=2 ; shift ;;
		"--laptop" )
			doMode=3 ; shift ;;
		"--load" )
			doMode=4 ; shift ;;
		"--adaptive" )
			doMode=5 ; shift ;;
		"--freq" )
			doMode=59 ;
			doFreq=80 ;
			frequency="${2}" ; shift ; shift ;;
		"--fmax" )
			doFreq=99 ; shift ;;
		"--fmidhi" )
			doFreq=98 ; shift ;;
		"--fmidlo" )
			doFreq=97 ; shift ;;
		"--fmin" )
			doFreq=96 ; shift ;;
		"--f"+([0-9]) )
			doFreq=$(echo "$1" | cut -c4- ) ; shift ;;
		"--default" )
			doDefault=1 ; shift ;;
		"--status" )
			doStatus=1 ; shift ;;
		"--cron" )
			doCron=1 ; shift ;;
		"--service" )
			doService=1 ; shift ;;
		* )
			echo "ERROR:  Invalid argument '${1}' on command line." ; exit 1 ;;
	esac
done

test ${dbg} -gt 0 && echo "	>>> END  parsing ..." >&2

if [ ${doService} -eq 1 ]
then
	rm -f /var/log/cpufreq.log
fi

if [ ${doStatus} -eq 1 ]
then
	if [ ${doCron} -eq 1 ]
	then
		{ reportStatus ; echo "" ; } >>/var/log/cpufreq.log
	else
		reportStatus
	fi
	exit
fi

getGov

getFreq
test ${dbg} -gt 1 && echo frequency = ${frequency} >&2

test ${doDefault} -eq 1 \
	&& { printf "\n Will use hard-coded presets:\n\t  governor = '${governor}'\n\t frequency = '${frequency}'\n\n" ; } \
	|| { printf "\n Will use selected governor: '${governor}' ...\n" ; }

setGovernor

if [ "${governor}" = "userspace" ]
then
	test ${doDefault} -eq 0 \
	&& { printf "\n Will use selected frequency: '${frequency}' ...\n" ; }

	setFrequency
fi

echo ""

test ${doService} -eq 0 && rm -i ${tmp}

exit 0
