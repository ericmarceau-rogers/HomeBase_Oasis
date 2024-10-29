#!/bin/bash

####################################################################################################
###
###	Script to simplify interraction with ffmpeg for recording from video stream
###
###	AUTHOR:		Eric Marceau, Ottawa, Canada
###	Version:	3.0  2024-10-29		
###	License:	GNU AGPLv3
###
###HELPSTART
###	Command line options:
###
###	--slices {count}
###	--single		[default if neither specified]
###		These options are mutually exclusive.
###		{count} is the number of equal-length video files the will be created.
###		"--single" will force the entire recording as a one file only.
###
###	--hours {hours}
###	--minutes {minutes}
###		These options are mutually exclusive.
###		Specify the length of the total recording time in either {hours} or {minutes}.
###		No fractional/decimal values permitted.
###
###	--wait {minutes}
###		This options tells the script to wait the specified {minutes} before starting the recording.
###
###	--label_hms		[default if neither specified]
###	--label_int
###		These options are mutually exclusive.
###		"--label_hms" will add start time of recording to filenames 
###		              using the format specifier '%Y%m%d_%H%M%S'.
###		"--label_int" will add start time of recording to filenames
###			      using the format specifier '%Y%m%d_%H%M'_##m.
###
###	--label {string}	[if not specified, default value is 'vidrecord']
###		This allows the custom specification of a prefix string for the video files.
###		When defining this, note that one of the options "--label_int" or "--label_hms"
###		              already includes one of the two pre-defined "date and time"
###			      modifier strings for filename.
###		filename={string}_{modifierstring}.mp4
###
###	--posn { "ul" | "ur" | "ll" | "lr" }		[ "ul" is default position ]
###		This specifies the placement of the timestamp string at one of the
###			      4 corners of the video window
###				ul => upper left
###				ur => upper right
###				ll => lower left
###				lr => lower right
###
###	--dark
###	--light	
###		These options are mutually exclusive.
###		Selection of background for timestamp text.
###			      "--black" specified white text on black background.
###			      "--light" specified black text on white background.
###
###	Examples:
###
###	VIDEO__Record_LiveStreamWithTimeStamp.sh --single --minutes 120 --label_int
###
###		 Starting capture of video stream for next 120 minutes as:
###		 -> vidrecord_20241024_1741_120m.mp4
###
###
###	VIDEO__Record_LiveStreamWithTimeStamp.sh --slices 6 --hours 2 --label_hms
###
###		 Starting capture of video stream for next 20 minutes as:
###		 -> vidrecord_20241024_181047.mp4
###
###
###	VIDEO__Record_LiveStreamWithTimeStamp.sh --single --minutes 120 --label_int --label myvid --wait 2
###
###		 WAITING 2 minute(s) before proceed with video recording ...
###		 Starting capture of video stream for next 120 minutes as:
###		 -> myvid_20241027_1725_120m.mp4
###	
###	REF:  https://askubuntu.com/a/428501
###	REF:  https://ubuntu-mate.community/t/cheese-recording-not-showing-landlord-coming-into-my-trailer-for-repair/28390/9
###HELPEND
###
###	FUTURES:
###	* systemd service
###	* option to specify video repository directory
###	* option to specify purging old videos by age
###
####################################################################################################


show_help()
{
	awk 'BEGIN{
		doPrint=0 ;
	}{
		if( $1 ~ /###HELPEND/ ){
			doPrint=0 ;
		} ;
		if( doPrint == 1 ){
			gsub(/^###/, "", $0 ) ;
			print $0 ;
		} ;
		if( $1 ~ /###HELPSTART/ ){
			doPrint=1 ;
		} ;
	}' <$0
}

####################################################################################################
recordSegment()
{

	###
	### Options used in REF which were not used by Pavlos in his response demo
	###
	#	-f video4linux2			\
	#	-s 640x480			\
	#	-r 30				\
	#	-vcodec libx264			\
	#	-vb 2000k 			\

	ffmpeg	\
	-i /dev/video0			\
	-preset ultrafast		\
	${segInterval}			\
	-vf "${textOverlayParameters}"	\
	-f mp4 "${videoFile}"
}


####################################################################################################
recordSlice()
{
	videoFile="${videoFilePref}_${sliceStart}.mp4"
	printf "\n\t Starting capture of video stream for next ${sliceMax} minutes as:\n\t -> ${videoFile}\n"

	recordSegment
}


specify_timestamp()
{
####################################################################################################
###
###	'drawtext' Option Specifications for TimeStamp Placement and Styling
###
col_light="white@0.8"
col_dark="black"

case ${dark} in
	1)	txt="${col_light}"
		bkg="${col_dark}"
		;;
	2)	txt="${col_dark}"
		bkg="${col_light}"
		;;
esac

###
###	Specifying Background Attributes
###
bkgd_toggle="box=1"
bkgd_color="boxcolor=${bkg}"
bkgd_margin="boxborderw=5"

###
###	Specifying Timestamp Attributes
###
#fontSpec="fontfile=DejaVuSans-Bold.ttf"
size=14
fontSize="fontsize=${size}"
fontSpec="fontfile=FreeMono.ttf"
fontClr="fontcolor=${txt}"

###
###	Specifying Text Position
###
### coordinates specify the upper left corner of the text string's position
### x=0,y=0 at upper left corner of video
margin=7
case "${locn}" in
	"ul" )
		### default
		timePosn="x=${margin}:y=${margin}"
		;;
	"bl" )
		### option for bottom left corner
		timePosn="x=${margin}:y=(h-text_h-${margin}-${size})"
		;;
	"ur" )
		### option for upper right corner
		timePosn="x=(w-text_w-${margin}):y=${margin}"
		;;
	"br" )
		### option for bottom right corner
		timePosn="x=(w-text_w-${margin}):y=(h-text_h-${margin}-${size})"
		;;
	* ) printf "\n\t Invalid parameter used on command line. \n\t Only valid options for "--posn" :  ul | bl | ur | br  \n Bye!\n\n" ; exit 1
esac

#timeFmt="text='\\%T'"
timeFmt="text='\\%{localtime}'"

textOverlayParameters="drawtext=${bkgd_toggle}:${bkgd_color}:${bkgd_margin}:${fontSpec}:${timeFmt}:${fontClr}:${timePosn}"

#echo ${textOverlayParameters}
#exit
}


####################################################################################################

locn="ll"
mode=1
timeTot=0
timeWait=0
count=0
label=0
dark=1
videoFilePref="vidrecord"

sliceMax=0
 
while [ $# -gt 0 ]
do
	case "${1}" in
		"--help" )
			show_help
			exit 0
			;;
		"--single" )
			mode=1
			shift
			;;
		"--dark" )
			dark=1
			shift
			;;
		"--light" )
			dark=0
			shift
			;;
		"--slices" )
			### number of recording slices to cover specified duration
			mode=2
			slices="${2}"
			shift ; shift
			;;
		"--hours" )
			### total recording time		[ units in hours ]
			timeTot=$( expr ${2} \* 60 )
			count=1
			shift ; shift
			;;
		"--minutes" )
			### total recording time		[ units in minutes ]
			timeTot="${2}"
			count=1
			shift ; shift
			;;
		"--wait" )
			### wait time before start		[ units in minutes ]
			timeWait="${2}"
			shift ; shift
			;;
		"--label" )
			videoFilePref="${2}"
			shift ; shift
			;;
		"--label_int" )
			label=1
			shift
			;;
		"--label_hms" )
			label=0
			shift
			;;
		"--posn" )
			locn="${2}"
			shift ; shift
			;;
		* ) printf "\n\t Invalid parameter used on command line. \n\t Only valid options: [ --single | --slices {count} ] [ --hours {hours} | --minutes {minutes} ] [ --wait {minutes} ] [ --label {string} ] [ --label_int | --label_hms ] [ --posn [ ul | ur | ll | lr ] ] \n Bye!\n\n" ; exit 1
	esac
done


specify_timestamp

####################################################################################################


if [ ${mode} -eq 1 ]
then
	test ${timeTot} -eq 0 && { printf "\n\t ERROR:  Need to specify total record time with one of '--hours {hours}' or '--minutes' {minutes} options.\n Bye!\n\n" ; exit 1 ; }
	
	if [ ${timeWait} -gt 0 ]
	then
		printf "\n\t WAITING ${timeWait} minute(s) before proceed with video recording ...\n\n"
		hTime=$( expr ${timeWait} \* 60 )
		sleep ${hTime}
	fi

	#sliceMax=$( expr ${timeTot} \* 60 )
	sliceMax=${timeTot}
	segInterval="-t $( expr ${sliceMax} \* 60 )"

	if [ ${label} -eq 1 ]
	then
		sliceStart="$(date '+%Y%m%d_%H%M' )_${sliceMax}m"
	else
		sliceStart=$(date '+%Y%m%d_%H%M%S' )
	fi

	recordSlice
	exit
fi


if [ ${mode} -eq 2 ]
then
	test ${timeTot} -eq 0 && { printf "\n\t ERROR:  Need to specify total record time with '--duration {hours}' option.\n Bye!\n\n" ; exit 1 ; }

	if [ ${timeWait} -gt 0 ]
	then
		printf "\n\t WAITING ${timeWait} minute(s) before proceed with video recording ...\n\n"
		hTime=$( expr ${timeWait} \* 60 )
		sleep ${hTime}
	fi

	#duration=$( expr ${timeTot} \* 60 )
	duration=${timeTot}
	sliceMax=$( expr ${duration} / ${slices} )
	segInterval="-t $( expr ${sliceMax} \* 60 )"

	indx=0
	while [ ${indx} -lt ${slices} ]
	do
		if [ ${label} -eq 1 ]
		then
			sliceStart="$(date '+%Y%m%d_%H%M' )_${sliceMax}m"
		else
			sliceStart=$(date '+%Y%m%d_%H%M%S' )
		fi

		recordSlice
		indx=$( expr ${indx} + 1 )
	done
	exit
fi


exit
