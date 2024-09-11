#!/bin/sh

lsblk -l | awk '{ if( length($1) == 3 ){ print $0 } ; }' | awk '{ printf("\t\t %s\n", $0 ) ; }'
