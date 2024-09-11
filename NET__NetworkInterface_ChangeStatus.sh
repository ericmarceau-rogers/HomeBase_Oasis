#!/bin/sh

############################################################################################################
###
###	$Id: NET__NetworkInterface_ChangeStatus.sh,v 1.7 2022/08/19 19:15:26 root Exp $
###
###	Script to manage the actions of taking down and raising the network function on the internet interface.
###
############################################################################################################


BASE=/tmp/tmp.`basename $0 ".sh" `.$$

usage()
{
	echo "\n\t Only options available are [ --down | --up | --reset | --verbose | --details ].\n Bye!\n" ; exit 1
}


if [ $# -eq 0 ]
then
	usage
fi

verbose=0
doReset=0
while [ $# -gt 0 ]
do
	case $1 in
		--reset )	command="ifup"   ; doReset=1 ; shift ;;
		--down )	command="ifdown" ; shift ;;
		--up )		command="ifup" ; shift ;;
		--verbose )	verbose=1 ; shift ;;
		--details )	details="--verbose" ; shift ;;
		* ) echo "\n\t Invalid option '$1' entered on the command line." ; usage ;;
	esac
done

if [ "${details}" = "--verbose" ]
then
	if [ -z "${command}" ] ; then  command="ifup" ; doReset=1 ; fi

	#/etc/udev/rules.d/70-persistent-net.rules
	echo "\n Output from command 'service networking restart':\n"
	service networking restart | awk '{ printf("\t %s\n", $0 ) }'
	echo "         ------------------------------------------------------               "

	echo "\n Contents of the file 'cat /etc/network/interfaces':\n"
	cat /etc/network/interfaces | awk '{ printf("\t %s\n", $0 ) }'
	echo "         ------------------------------------------------------               "

	echo "\n Output from command 'lshw -class network':\n"
	lshw -class network | awk '{ printf("\t %s\n", $0 ) }'
	echo "         ------------------------------------------------------               "

	echo "\n Output from command 'route -n':\n"
	route -n | awk '{ printf("\t %s\n", $0 ) }'
fi

#interface=`route -n | awk '{ if( $1 == "default" || $1 == "0.0.0.0" ) { print $8 }' | sort | uniq `
#interface=`grep 'dhcp' /etc/network/interfaces | grep -v '^#' | awk '{ print $2 }' | sort | uniq `
#interface=`ifconfig | grep 'flags=' | grep -v 'lo:' | cut -f1 -d\: `

for interface in `ifquery --list | grep -v '^lo' `
do
	ifconfig ${interface} 2>&1 >${BASE}.pre

	up=0
	testor=`grep 'inet' ${BASE}.pre `
	if [ -n "${testor}" ] ; then up=1 ; fi

	doit=1
	case ${command} in
		ifdown ) if [ ${up} -eq 0 ] ; then  direction="DOWN" ; doit=0 ; fi ;;
		ifup )   if [ \( ${doReset} -eq 0 \) -a \( ${up} -eq 1 \) ] ; then  direction="UP"   ; doit=0 ; fi ;;
	esac

	if [ ${doit} -eq 1 ]
	then
		echo "\n#####################################################################################"

		if [ ${verbose} -eq 1 ]
		then
			echo "[BEFORE]"
			cat ${BASE}.pre | awk '{printf("\t %s\n",$0)}'
			echo "         ------------------------------------------------------               "
		fi

		if [ ${doReset} -eq 1 ]
		then
			echo " ifdown ${details} ${interface} ..."
			ifdown ${details} ${interface} 2>&1 | awk '{printf("\t\t %s\n",$0)}'
			sync
			echo "\n         ------------------------------------------------------               "

			###     To be run after installing local customized version of /etc/network/interfaces (i.e. interfaces.Oasis).
			systemctl stop networking
			#systemctl stop resolvconf.service
			ip address flush dev enp2s0     # just to be safe

			commonAction="restart"
			systemctl ${commonAction} systemd-resolved.service
			#systemctl ${commonAction} resolvconf.service
 			#systemctl enable resolvconf.service

			systemctl ${commonAction} NetworkManager.service
			systemctl ${commonAction} NetworkManager-wait-online.service
			systemctl ${commonAction} NetworkManager-dispatcher.service
			systemctl ${commonAction} network-manager.service

			systemctl start networking
			systemctl ${commonAction} networking.service

			systemctl restart dnscrypt-proxy-resolvconf.service
			systemctl ${commonAction} dnscrypt-proxy.service
			systemctl ${commonAction} networkd-dispatcher.service
			systemctl ${commonAction} networking.service
			systemctl ${commonAction} NetworkManager-wait-online.service
			systemctl ${commonAction} NetworkManager.service
			systemctl ${commonAction} openvpn.service
			systemctl ${commonAction} ModemManager.service
			systemctl ${commonAction} systemd-resolved.service
			systemctl ${commonAction} dnscrypt-proxy.socket
			systemctl ${commonAction} network-online.target
			systemctl ${commonAction} ifup@enp2s0.service
			systemctl ${commonAction} ifupdown-pre.service
		fi

		echo " ${command} ${details} ${interface} ..."
		${command} ${details} ${interface} 2>&1 | awk '{printf("\t\t %s\n",$0)}'
		sync

		if [ ${verbose} -eq 1 ]
		then
			systemd-resolve --status

			echo "\n         ------------------------------------------------------               "

			echo "[AFTER]"
			ifconfig ${interface} 2>&1 >${BASE}.post
			cat ${BASE}.post | awk '{printf("\t %s\n",$0)}'
		fi

		echo "\n#####################################################################################\n"
	else
		echo "[${interface}] Interface is already in requested state: ${direction}"
		if [ ${verbose} -eq 1 ] ; then  cat ${BASE}.pre | awk '{printf("\t %s\n",$0)}' ; fi
	fi
	rm -f ${BASE}.*
done

exit 0
exit 0
exit 0


