#!/bin/bash

###
###	Script to demonstrate the output formatting from the function 'ndate'
###


ndate()
{
	awk '{
		pos=index( $0, $9 ) ;
		rem=substr( $0, pos ) ;
		printf("%s %3d %10s %10s %10d  %3s %2d %5s  %s\n", $1, $2, $3, $4, $5, $6, $7, $8, rem ) ;
	}'
}


echo "\
-rwxr-x--- 1 root root 33639 Jul  5  2023 Calibre__linux-installer.sh
-rwxr-xr-x 1 root root 6375 Oct 17 20:49 Devices__ProbeAndReport_ActualHardware.sh
-rwxr-x--- 1 root root 501 Sep 27 23:58 Devices__USB_TestWriteSpeed.sh
-rw-r--r-- 1 root root 1586 Aug  7 17:16 HW__FanSpeedController.sh
-rwxr-xr-x 1 root root 1716 Nov 17 18:08 NET__Modem_GetReport_Status.sh
-rwxr-x--- 1 root root 3150 Oct 13 17:55 OS_Admin__CreateServiceDefinition.sh
-rwxr-x--- 1 root root 11801 Jun 28 21:44 OS_Admin__CreateSwapfile.sh
-rwxr-x--- 1 root root 7768 Oct  3 18:41 OS_Admin__IdentifyRequiredPackagesForCoding.sh
-rwxr-x--- 1 root root 241 Dec 13 00:26 OS_Admin__Kernel_ListModules.sh
-rwxr-x--- 1 root root 357 Aug  3 18:17 OS_Admin__Kernel_ListParmVals.sh
-rwxr-x--- 1 root root 1412 Sep 28 22:32 UTIL__FindCommandReference.sh
-rwxr-x--- 1 root root 1140 Jul 14 17:20 Upgrade_22.04__ReinstallRemovedHardwarePackages.sh
-rwxr-x--- 1 ericthered ericthered 513 Dec 10 22:08 copy__TarUsingFileList.sh
-rwxr-x--- 1 root root 406 Nov 22  2022 getCommandLists.sh
-rwxr-x--- 1 root root 192 Nov 15 12:47 myExpect.sh
-rwxr-x--- 1 root root 465 Nov 15 13:05 myExpect_test.sh
-rwxr-x--- 1 ericthered ericthered 253 Dec 10 22:08 prompt__CompareDetailsDelete.sh
-rw-r--r-- 1 root root 22901 Aug  5 18:01 scaling_governor.sh
-rwxr-xr-x 1 root root 847 Nov 17 18:08 scrapeTest.sh
-rw-r--r-- 1 root root 4 Dec 13 15:06 test.bash" | ndate
