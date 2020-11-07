#!/bin/sh

#-rw------- userid/userid  188677 2015-08-22 19:37 userid/.mozilla_Iter_G+0__MASTER/firefox/OasisMega1.FirefoxProfile_DEFUNCT/bookmarkbackups/book
marks-2015-08-22_1647_ojj2KWL3C2TaTr3aiUZC8Q==.jsonlz4

tar tvf "$1" | awk '{ print $4, $5 }' | sort -nr | head -1
