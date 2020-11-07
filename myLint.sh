#!/bin/sh

###	$Id: $
###	Script to parse other script for missing component of pairings.

parseIt5()
{
TMP=/tmp/$LOGNAME.$P.$$
{
cat <<-!EOF
fs1=\' ;
n=split($0,p,fs1) ;
if ( n == 2 ) {
printf("%6s %s:   %s\n", NR, n, $0);
}
if ( n == 4 ) {
printf("%6s %s:   %s\n", NR, n, $0);
}
if ( n == 6 ) {
printf("%6s %s:   %s\n", NR, n, $0);
}
if ( n == 8 ) {
printf("%6s %s:   %s\n", NR, n, $0);
}
!EOF
} >$TMP
cat $TMP
      awk  -f $TMP
}

parseIt1()
{
      awk -v fs1="{" -v fs2="}" '{
              n1=split($0,p,fs1);
              n2=split($0,p,fs2);
              if ( n1 != n2 ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

parseIt2()
{
      awk -v fs1="(" -v fs2=")" '{
              n1=split($0,p,fs1);
              n2=split($0,p,fs2);
              if ( n1 != n2 ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

parseIt3()
{
      awk -v fs1="\"" '{
              n=split($0,p,fs1);
              if ( (n == 2) || (n == 4) || (n == 6) || (n == 8) || (n == 10) || (n == 12) ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

parseIt4()
{
      awk -v fs1="\`" '{
              n=split($0,p,fs1);
              if ( (n == 2) || (n == 4) || (n == 6) || (n == 8) || (n == 10) || (n == 12) ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

parseIt6()
{
      awk -v fs1="'" '{
              n=split($0,p,fs1);
              if ( (n == 2) || (n == 4) || (n == 6) || (n == 8) || (n == 10) || (n == 12) ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

batchIt=0

if [ $# -ne 0 ]
then

	while [ true ]
	do
		case $1 in
			--batch ) batchIt=1 ; shift ;;
			* ) break ;;
		esac
	done

   for file in $*
   do
      if [ ${batchIt} -eq 1 ] ; then  
	echo "\n########################################################################################################"
	echo   "########################################################################################################"
        echo   " FILE:  ${file} ..."
      else
        echo "\n FILE:  ${file} ..."
      fi

      echo "\n-----------------------------------------------------------------------------------------------\n Phase I - checking braces ..."
      cat $file |
      parseIt1
      if [ ${batchIt} -eq 0 ] ; then  echo "\n Hit return to continue ...\c" ; read k ; fi

      echo "\n-----------------------------------------------------------------------------------------------\n Phase II - checking brackets ..."
      cat $file |
      parseIt2
      if [ ${batchIt} -eq 0 ] ; then  echo "\n Hit return to continue ...\c" ; read k ; fi

      echo "\n-----------------------------------------------------------------------------------------------\n Phase III - checking double-quotes ..."
      cat $file |
      parseIt3
      if [ ${batchIt} -eq 0 ] ; then  echo "\n Hit return to continue ...\c" ; read k ; fi

      echo "\n-----------------------------------------------------------------------------------------------\n Phase IV - checking back-quotes ..."
      cat $file |
      parseIt4
      if [ ${batchIt} -eq 0 ] ; then  echo "\n Hit return to continue ...\c" ; read k ; fi

      echo "\n-----------------------------------------------------------------------------------------------\n Phase VI - checking single-quotes ..."
      cat $file |
      parseIt6
      if [ ${batchIt} -eq 0 ] ; then  echo "\n Hit return to continue ...\c" ; read k ; fi

   done
   echo "\n Done!\n"
else
      cat |
      parseIt
fi


exit 0
exit 0
exit 0
