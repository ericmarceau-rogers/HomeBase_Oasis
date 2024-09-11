#!/bin/sh

#############################################################################################
###
###	$Id: $
###
###	Script to report known routing info for NETWORK interfaces.
###
#############################################################################################

ip route show type local table all

exit 0
exit 0
exit 0


#++#  https://serverfault.com/questions/372476/restricting-output-to-only-allow-localhost-using-iptables?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

If your machine has multiple interfaces, and you try to communicate with the IP on one of these other interfaces, the traffic will actually go over the lo interface. Linux is smart enough to figure out this traffic is destined for itself, and not try to use the real interface.
The rule -A OUTPUT -o lo -j ACCEPT will allow this other traffic, while the rule -A OUTPUT -o lo -s 127.0.0.1 -d 127.0.0.1 -j ACCEPT would reject it.
.
You can see everything the kernel will route over the loopback interface by running

ip route show type local table all

(just note the first value, which is either an IP or a network/mask)
