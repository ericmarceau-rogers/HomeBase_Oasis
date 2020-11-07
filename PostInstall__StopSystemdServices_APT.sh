#!/bin/sh

echo "\n Will open editing session to edit config file for systemd timers.  Change value of 'OnBootSec' as shown below

# apt-daily timer configuration override   
[Timer]   
OnBootSec=20h			<< MODIFY THIS LINE !!!
OnUnitActiveSec=1d   
AccuracySec=1h   
RandomizedDelaySec=30min 

 NOTE: Will only have impact at next boot.

 Hit return to continue with edit session in >> systemctl editor << ... \c" ; read k
echo ""

systemctl edit apt-daily.timer

systemctl disable apt-daily.service
systemctl disable apt-daily.timer

systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service

while [ true ]
do
	clear
	ps -ef | grep apt
	echo "\n Hit <ctl-c> to terminate ..."
	sleep 5
done
