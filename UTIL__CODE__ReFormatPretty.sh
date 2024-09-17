#!/bin/bash

###	Hack for attempt at de-obfuscating javascript, css, and similarly formatted files

###	Intended to insert newline at evey semicolon and opening and closing brace
###	Open brace triggers indentation action until closing brace reduces indentation amount

prettify()
{
	awk '{
		gsub(/[;]/,";\n") ;
		gsub(/[{]/,"{\n") ;
		gsub(/[}]/,"\n}\n") ;
		print $0 ;
	}' |
	awk -v dbg=${debug} 'BEGIN{
		indent=0 ;
	}{
		if( $1 == "}" ){
			indent-- ;
			if( indent == -1 ){
				indent++ ;
				if( dbg ==1 ){ print indent, NR | "cat 1>&2" ; } ;
			}else{
				if( dbg ==1 ){ print indent | "cat 1>&2" ; } ;
			} ;
		} ;

		if( indent == 0 ){
			print $0 ;
		}else{
			for( i=1 ; i <= indent ; i++ ){
				printf("\t") ;
			} ;
			print $0 ;
		} ;

		if( index($0,"{") > 0 ){
			indent++ ;
			if( dbg == 1 ){ print indent | "cat 1>&2" ; } ;
		} ;
	}'
}

PIPE=0

while [ $# -gt 0 ]
do
	case $1 in
		--stream ) PIPE=1 ; shift ;;
		--file )   PIPE=0 ; INPUT="$2" ; shift ; shift ;;
		* ) printf "\n\t Invalid option provided on the command line.  Only available: [ --stream | --file {filename} ]\n\n" ; exit 1 ;;
	esac
done

if [ ${PIPE} -eq 1 ]
then
	prettify
else
	prettify < ${INPUT}
fi

exit

###	Failed logic

	#head ${INPUT}

	#tr ; "\n" < ${1}
	#sed 's+;+;\n+g' < ${INPUT} |
	#sed 's+}+}\n+g'

	#sed 's+;+;\'$'\n\'+g' < ${INPUT} |
	#sed 's+}+}\'$'\n\'+g'

	#sed $'s+;+;\\\n+g' < ${INPUT} |
	#sed $'s+}+}\\\n+g'

	#characterNeverEncounterd="¥"
	#sed "s+;+;${characterNeverEncountered}+g" < ${INPUT} |
	#sed "s+[}]+[}]${characterNeverEncountered}+g" |
	#tr ${characterNeverEncountered} '\n'

	#sed 's+;+;¥+g' < ${INPUT} |
	#sed 's+[{]+{¥+g' < ${INPUT} |
	#sed 's+\{+\{\®+g' < ${INPUT} |
	#tr '[®]' "\n"
	#sed 's+}+}¥+g' |

