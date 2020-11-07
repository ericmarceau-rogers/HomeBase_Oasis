#!/bin/sh

###	$Id: $
###	Script to report details about the BIOS on the current host.

dmidecode >BIOS_CharacteristicsReport.txt

more BIOS_CharacteristicsReport.txt

echo "\n\t BIOS particulars saved as 'BIOS_CharacteristicsReport.txt'.\n"
