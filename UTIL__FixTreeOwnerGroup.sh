#!/bin/sh

TMP=/tmp/`basename "$0" ".sh" `.tmp


#UTIL__FixTreeOwnerGroup.sh --oUID 209 --oGRP crontab --nUSR ericm --nGRP dvm --sample --force


TREE="/DB001_F7/ProjectDir"

showMatchUser()
{
	find ${TREE} -xdev -uid ${cUID} -exec ls -ld {} \; | awk -v showit="${SHOWIT}" -v user="${cUID}" -v remain="${REMAIN}" 'BEGIN{ counter=0 }{ if( $3 == user ){ if( showit == 1 ){ print $0 } ; counter++ ; } ; }END{ printf("\n\t Total User Match Count %s= %s\n", remain, counter ) ; }'
}	# showMatchUser()

showNoMatchUser()
{
	rm -f ${TMP}.exceptions
	find ${TREE} -xdev \( ! -uid ${cUID} \) -exec ls -ld {} \; | awk -v user="${cUID}" '{ if( $3 != user ){ print $0 } ; }' > ${TMP}.exceptions
	if [ -s ${TMP}.exceptions ]
	then
		cat ${TMP}.exceptions
	else
		echo "\t\t None found.\n"
	fi
}	# showNoMatchUser()


showMatchGroup()
{
	find ${TREE} -xdev -group ${cGroup} -exec ls -ld {} \; | awk -v showit="${SHOWIT}" -v group="${cGroup}" -v remain="${REMAIN}" 'BEGIN{ counter=0 }{ if( $4 == group ){ if( showit == 1 ){ print $0 } ; counter++ ; } ; }END{ printf("\n\t Total Group Match Count %s= %s\n", remain, counter ) ; }'
}	# showMatchGroup()

showNoMatchGroup()
{
	rm -f ${TMP}.exceptions
	find ${TREE} -xdev \( ! -group ${cGroup} \) -exec ls -ld {} \; | awk -v group="${cGroup}" '{ if( $4 != group ){ print $0 } ; }' > ${TMP}.exceptions
	if [ -s ${TMP}.exceptions ]
	then
		cat ${TMP}.exceptions
	else
		echo "\t\t None found.\n"
	fi
}	# showNoMatchGroup()

useUID=0

cUID="-99"
cOwner=""
cGID="-99"
cGroup=""

Owner=""
Group=""

VERB=""
SAMPLE=0
FORCE=0
SHOW=1

while [ $# -gt 0 ]
do
	case $1 in
		--verbose ) VERB="-v" ; shift ;;
		--sample )   SAMPLE=1 ; shift ;;
		--force )     FORCE=1 ; shift ;;
		--nomatch )    SHOW=0 ; shift ;;
		--match )      SHOW=1 ; shift ;;

		--oUID )      cUID=$2 ; useUID=1 ; shift ; shift ;;
		--oUSR )    cOwner=$2 ; useUID=0 ; shift ; shift ;;
		--oGID )      cGID=$2 ; useGID=1 ; shift ; shift ;;
		--oGRP )    cGroup=$2 ; useGID=0 ; shift ; shift ;;

		--nUSR )     Owner=$2 ; shift ; shift ;;
		--nGRP )     Group=$2 ; shift ; shift ;;
	esac
done

###
###	OK TO USE:	usermod  --uid UID
###	UNDER REVIEW:	usermod  --gid GID
###	OK TO USE:	groupmod --gid GID
###

if [ ${useUID} -eq 1 -a ${cUID} -eq -99 ] ; then  echo "\n\t  You must use '--oUID' to provide the UID for the files that need to be located for updating with new User Name.\n" ; exit 1 ; fi
if [ ${useUID} -eq 0 -a -z "${cOwner}" ] ; then  echo "\n\t  You must use '--oUSR' to provide the User Name for the files that need to be located for updating with new User Name.\n" ; exit 1 ; fi

if [ ${useGID} -eq 1 -a ${cGID} -eq -99 ] ; then  echo "\n\t  You must use '--oGID' to provide the GID for the files that need to be located for updating with new Group Name.\n" ; exit 1 ; fi
if [ ${useGID} -eq 0 -a -z "${cGroup}" ] ; then  echo "\n\t  You must use '--oGRP' to provide the Group Name for the files that need to be located for updating with new Group Name.\n" ; exit 1 ; fi

if [ -z "${Owner}" ] ; then  echo "\n\t  You must use '--nUSR' to provide the new User Name that will be assigned to the files that have been located.\n" ; exit 1 ; fi
if [ -z "${Group}" ] ; then  echo "\n\t  You must use '--nGRP' to provide the new Group Name that will be assigned to the files that have been located.\n" ; exit 1 ; fi

#####  Reference values
#cUID="209"
#cOwner="ericm"
#cGID="105"
#cGroup="crontab"
#Owner="ericm"
#Group="dvm"


if [ ${FORCE} -eq 1 ]
then
	SHOWIT=0
	REMAIN="(remaining) "

	if [ "${SAMPLE}" -eq 1 ]
	then
		find ${TREE} -xdev -group ${cGroup} -print | head -10 | xargs chgrp -v -h ${Group}
		showMatchGroup
		echo ""

		find ${TREE} -xdev -uid ${cUID}     -print | head -10 | xargs chown -v -h ${Owner}
		showMatchUser 
	else
		find ${TREE} -xdev -group ${cGroup} -exec chgrp ${VERB} -h ${Group} {} \;
		showMatchGroup
		echo ""

		find ${TREE} -xdev -uid ${cUID}     -exec chown ${VERB} -h ${Owner} {} \;
		showMatchUser 
	fi
	echo ""

else
	if [ ${SHOW} -eq 1 ]
	then
		SHOWIT=1
		REMAIN=""
		showMatchGroup
		echo""
		showMatchUser 
	else
		# List of items that will not be modified:
		echo "\n\t Exceptions list:"

		SHOWIT=0
		REMAIN=""
		showNoMatchGroup
		echo""
		showNoMatchUser 
	fi
fi
