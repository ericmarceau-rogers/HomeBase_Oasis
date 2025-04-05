#!/bin/sh

dbg=0
if [ "$1" = "--progress" ] ; then  dbg=1 ; fi

cd ${index}
test $? -eq 0 || { echo "\n\t Unable to set '${index}' as working directory.  Task abandoned.\n BYe! \n" ; exit 1 ; }

doFunction="doChar"


doBar()
{
	LC_ALL=C awk '{ if( index($0,"|") != 0 ){ print $0 ; } ; }' <"${indxFile}" >"BAR_${indxFile}"
	test -s "BAR_${indxFile}" || { rm -vf "BAR_${indxFile}" ; }
}

doBrace()
{
	LC_ALL=C awk -v verb=${dbg} '{ if( index($0,"{") != 0 || index($0,"}") != 0 ){
		if( verb == 1 ){ printf("\t pat = \"{|}\" |%s\n", $0 ) | "cat 1>&2" ;  } ;
			print $0 ;
		} ;
	}' <"${indxFile}" >"BRACE_${indxFile}"
	test -s "BRACE_${indxFile}" || { rm -vf "BRACE_${indxFile}" ; }
}

doBrktRnd()
{
	LC_ALL=C awk -v verb=${dbg} '{ if( index($0,"(") != 0 || index($0,")") != 0 ){
		if( verb == 1 ){ printf("\t pat = \"(|)\" |%s\n", $0 ) | "cat 1>&2" ;  } ;
			print $0 ;
		} ;
	}' <"${indxFile}" >"BRK_RND_${indxFile}"
	test -s "BRK_RND_${indxFile}" || { rm -vf "BRK_RND_${indxFile}" ; }
}

doBrktSqr()
{
	LC_ALL=C awk -v verb=${dbg} '{ if( index($0,"[") != 0 || index($0,"]") != 0 ){
		if( verb == 1 ){ printf("\t pat = \"[|]\" |%s\n", $0 ) | "cat 1>&2" ;  } ;
			print $0 ;
		} ;
	}' <"${indxFile}" >"BRK_SQR_${indxFile}"
	test -s "BRK_SQR_${indxFile}" || { rm -vf "BRK_SQR_${indxFile}" ; }
}

doChar()
{
	#for pattern in "[']" '[`]' '["]' '[~]' '[!]' '[&]' '[$]' '[*]' '[?]' '[:]' '[;]' '[%]' '[,]' '[=]' '[@]' '[<]' '[>]' '[#]' '[+]' "[\^]"
	#do

	LC_ALL=C awk -v verb=${dbg} -v pat=${pattern} '{
		n=length($0) ;
		if( $0 ~ pat ){
			if( verb == 1 ){ printf("\t pat = \"%s\" |%s\n", pat, $0 ) | "cat 1>&2" ;  } ;
			printf("%s|%s\n", pat, $0 ) ;
		} ;
	}' <"${indxFile}" >"PUNCT_${indxFile}"
	#}' <"${indxFile}" | sort --version-sort >"PUNCT_${indxFile}"
	#done >"PUNCT_${indxFile}"
	test -s "PUNCT_${indxFile}" || { rm -vf "PUNCT_${indxFile}" ; }
}

echo "
	Select the character for which to generate a report:

	 1	[']
	 2	[\`]
	 3	[\"]
	 4	[~]
	 5	[!]
	 6	[&]
	 7	[$]
	 8	[*]
	 9	[?]
	10	[:]
	11	[;]
	12	[%]
	13	[,]
	14	[=]
	15	[@]
	16	[<]
	17	[>]
	18	[#]
	19	[+]
	20	[^]

	90	[|]
	91	[{}]
	92	[()]
	93	[\[\]]
	
	Enter selection [1-20,90-93] => \c" ; read ans

if [ -z "${ans}" ] ; then  exit ; fi

case ${ans} in
	 1 ) pattern="[']" ;;
	 2 ) pattern='[`]' ;;
	 3 ) pattern='["]' ;;
	 4 ) pattern='[~]' ;;
	 5 ) pattern='[!]' ;;
	 6 ) pattern='[&]' ;;
	 7 ) pattern='[$]' ;;
	 8 ) pattern='[*]' ;;
	 9 ) pattern='[?]' ;;
	10 ) pattern='[:]' ;;
	11 ) pattern='[;]' ;;
	12 ) pattern='[%]' ;;
	13 ) pattern='[,]' ;;
	14 ) pattern='[=]' ;;
	15 ) pattern='[@]' ;;
	16 ) pattern='[<]' ;;
	17 ) pattern='[>]' ;;
	18 ) pattern='[#]' ;;
	19 ) pattern='[+]' ;;
	20 ) pattern='[\\^]' ;;

	90 ) doFunction="doBar" ;;
	91 ) doFunction="doBrace" ;;
	92 ) doFunction="doBrktRnd" ;;
	93 ) doFunction="doBrktSqr" ;;

	* )	echo "\n\t Invalid selection made.  Only valid choices:  [1-20] \n Bye!\n" ; exit 1
		;;
esac

for drv in 2 3 4 5 6 7
do
	indxFile="DB001_F${drv}.d.INDEX.txt"

	${doFunction}
done
