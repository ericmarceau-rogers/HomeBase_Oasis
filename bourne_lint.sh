#!/bin/sh
##################################################################################
#
# Vers: $Header: bourne_lint.sh,v 1.2 2002/06/12 13:56:17 emarceau Exp $
#
# Desc: Script which attempts to perform lint-like operations for Bourne shell scripts.
#     : VERY limited scope.  Needs to evolve further to match string pairs.
#
##################################################################################

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
      awk '{
              fs1="\{" ;
              fs2="\}" ;
              n1=split($0,p,fs1);
              n2=split($0,p,fs2);
              if ( n1 != n2 ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

parseIt2()
{
      awk '{
              fs1="\(" ;
              fs2="\)" ;
              n1=split($0,p,fs1);
              n2=split($0,p,fs2);
              if ( n1 != n2 ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

parseIt3()
{
      awk '{
              fs1="\"" ;
              n=split($0,p,fs1);
              if ( (n == 2) || (n == 4) || (n == 6) || (n == 8) || (n == 10) || (n == 12) ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

parseIt4()
{
      awk '{
              fs1="\`" ;
              n=split($0,p,fs1);
              if ( (n == 2) || (n == 4) || (n == 6) || (n == 8) || (n == 10) || (n == 12) ) {
                   printf("%6s %s:   %s\n", NR, n, $0)
              }
      }'
}

if [ $# -ne 0 ]
then
   for file in $*
   do

      echo "Phase I - checking braces ..."
      cat $file |
      parseIt1
      echo "\n Hit return to continue ...\c" ; read k

      echo "Phase II - checking brackets ..."
      cat $file |
      parseIt2
      echo "\n Hit return to continue ...\c" ; read k

      echo "Phase III - checking double-quotes ..."
      cat $file |
      parseIt3
      echo "\n Hit return to continue ...\c" ; read k

      echo "Phase IV - checking back-quotes ..."
      cat $file |
      parseIt4
      echo "\n Hit return to continue ...\c" ; read k

   done
else
      cat |
      parseIt
fi
exit
      echo "Phase I - checking single-quotes ..."
      cat $file |
      parseIt5
exit
