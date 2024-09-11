#!/bin/sh

port=9000
CMS_ROOT="/DB001_F5/LOCAL__Web"

cd "${CMS_ROOT}"
if [ $? -ne 0 ]
then
	echo "\n\t Unable to set "${CMS_ROOT}" as working directory for local web server. Unable to start!\n Bye!\n"
	exit 1
fi

if [ ! -d .logs ]
then
	mkdir -v .logs
fi

LOG=".logs/CMS_server.log"
ELOG=".logs/CMS_server.errlog"

if [ -f "${LOG}" ]
then
	mv -v "${LOG}" "${LOG}.OLD"
fi

if [ -f "${ELOG}" ]
then
	mv -v "${ELOG}" "${ELOG}.OLD"
fi

python3 -m http.server ${port} >"${LOG}" 2>"${ELOG}" &

echo "\n http server is now online at port #${port} \n"

exit 0
