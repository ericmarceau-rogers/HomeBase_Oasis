#!/bin/sh

###	grep forcefsck /etc/init/mountall.conf

SIGNAL_FILE="/forcefsck"

echo "-y" >${SIGNAL_FILE}

ls -l ${SIGNAL_FILE}
