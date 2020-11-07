#!/bin/sh

###	$Id: $
###	Script to explode PATH components into separate lines for easier visual scan.

echo "${PATH}" | awk -F: '{ for ( i=1 ; i<=NF ; i++ ) printf("%s\n", $i ) }'
