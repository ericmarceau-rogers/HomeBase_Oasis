#!/bin/sh

for disk in $(ls /proc/fs/ext? | sort | cut -c1-3 | sort | uniq )
do
	drive="/dev/${disk}"
	echo "\n\n #################################################################\n DEVICE = '${drive}'"
	hdparm -I ${drive}
done


# REF:	https://askubuntu.com/questions/768373/hard-drive-error-bad-missing-sense-data/1106020#1106020
#
# REF:	https://www.google.co.uk/search?hl=en-CA&as_q=%22seagate%22+%22linux%22+%22quirk%22+%22kernel%22&as_epq=&as_oq=&as_eq=&as_nlo=&as_nhi=&lr=&cr=&as_qdr=all&as_sitesearch=&as_occt=any&as_filetype=&tbs=
#
# REF:	https://askubuntu.com/questions/1385793/hdparm-standby-after-x-time-doesnt-work/1385822#1385822
