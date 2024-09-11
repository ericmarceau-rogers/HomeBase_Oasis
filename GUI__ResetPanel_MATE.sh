#!/bin/sh

PIDo=`pidof mate-panel`

#	Running the pidof command will return a number output. This number 
#	output is the process ID for the panel program. From here, you’ll 
#	be able to kill the frozen/broken Mate panel with the kill command.

kill ${PIDo}

#	Alternatively, if killing the program with the kill command and pidof
#	doesn’t work for you, try the killall command along with “mate-panel.”

echo "\n\t Doing 15 second pause to allow auto-restart of 'mate-panel' ..."
sleep 20

PIDn=`pidof mate-panel`

if [ "${PIDn}" != "${PIDo}" ]
then
	exit 0
fi

killall mate-panel

#	Once you’ve “killed” the panel, Mate should automatically bring up a new, 
#	working panel instantaneously, and your problems should be solved. 
#	If the system doesn’t bring up a new panel, you can call it in manually 
#	with the this command:  mate-panel &

echo "\n\t Doing 15 second pause to allow auto-restart of 'mate-panel'.  Will only initiate restart if that fails ..."
sleep 20

PIDt=`pidof mate-panel`

if [ -n "${PIDt}" ]
then
	exit 0
fi

echo "\n\t No 'mate-panel' detected.  Starting via background process ..."
nohup mate-panel &

echo "\n\t Doing 15 second pause before confirming successful auto-restart of 'mate-panel' ..."
sleep 20

PIDf=`pidof mate-panel`

if [ -z "${PIDf}" ]
then
	echo "\n\t FAILED to restart 'mate-panel' !!!   Investigate immediately.\n"
	exit 1
fi
