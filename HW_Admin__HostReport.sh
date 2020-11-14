#!/bin/sh

###	$Id: HW_Admin__HostReport.sh,v 1.1 2020/11/14 03:08:32 root Exp $
###	Script to report on various aspects of the current host OS, GUI, hardware, memory, storage, graphics.  

OPTIONS="-y 255 -c 0"

report_OS()
{
echo "\n\n######################################################################################################\n####   OPERATING SYSTEM DETAILS"

COM="inxi ${OPTIONS} -S -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#System:    Host: OasisMega1 Kernel: 5.3.0-53-generic x86_64 bits: 64 gcc: 7.5.0 Desktop: MATE 1.20.1 (Gtk 3.22.30-1ubuntu4) info: mate-panel dm: lightdm Distro: Ubuntu 18.04.4 LTS

COM="inxi ${OPTIONS} -I -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Info:      Processes: 216 Uptime: 3:25 Memory: 1342.1/3683.4MB Init: systemd v: 237 runlevel: 5 Gcc sys: 7.5.0 Client: Shell (MachineReport.s running in MachineReport.s) inxi: 2.3.56

COM="inxi -c 0 -f -xxx 2>&1 | tail --lines=+3"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; eval ${COM}
#           CPU Flags: 3dnow 3dnowext 3dnowprefetch abm apic clflush cmov cmp_legacy constant_tsc cpuid cr8_legacy
#           cx16 cx8 de extapic extd_apicid fpu fxsr fxsr_opt ht hw_pstate ibs lahf_lm lbrv lm mca mce misalignsse
#           mmx mmxext monitor msr mtrr nonstop_tsc nopl npt nrip_save nx osvw pae pat pdpe1gb pge pni popcnt pse
#           pse36 rdtscp rep_good sep skinit sse sse2 sse4a svm svm_lock syscall tsc vme vmmcall wdt

#COM="inxi -c 0 -f -xxx 2>&1 | tail --lines=+3 | cut -c12- | awk '{ printf(\"%s \", \$0 ) }' "
#echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ;  inxi -c 0 -f -xxx 2>&1 | tail --lines=+3 | cut -c12- | awk '{ printf("%s ", $0 ) }' ; echo ""
#CPU Flags: 3dnow 3dnowext 3dnowprefetch abm apic clflush cmov cmp_legacy constant_tsc cpuid cr8_legacy cx16 cx8 de extapic extd_apicid fpu fxsr fxsr_opt ht hw_pstate ibs lahf_lm lbrv lm mca mce misalignsse mmx mmxext monitor msr mtrr nonstop_tsc nopl npt nrip_save nx osvw pae pat pdpe1gb pge pni popcnt pse pse36 rdtscp rep_good sep skinit sse sse2 sse4a svm svm_lock syscall tsc vme vmmcall wdt

COM="inxi ${OPTIONS} -r -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Repos:     Active apt sources in file: /etc/apt/sources.list
#           deb http://archive.ubuntu.com/ubuntu bionic main restricted
#           deb http://archive.ubuntu.com/ubuntu bionic-updates main restricted
#           deb http://archive.ubuntu.com/ubuntu bionic universe
#           deb http://archive.ubuntu.com/ubuntu bionic-updates universe
#           deb http://archive.ubuntu.com/ubuntu bionic multiverse
#           deb http://archive.ubuntu.com/ubuntu bionic-updates multiverse
#           deb http://archive.ubuntu.com/ubuntu bionic-backports main restricted universe multiverse
#           deb http://archive.canonical.com/ubuntu bionic partner
#           deb http://archive.ubuntu.com/ubuntu bionic-security main restricted
#           deb http://archive.ubuntu.com/ubuntu bionic-security universe
#           deb http://archive.ubuntu.com/ubuntu bionic-security multiverse

}	#report_OS()


report_NETWORK()
{
echo "\n\n######################################################################################################\n####   NETWORKING DETAILS"

COM="inxi ${OPTIONS} -i -xxx 2>&1 | tail --lines=+2"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; eval ${COM}
#           IF: enp2s0 state: up speed: 1000 Mbps duplex: full mac: 00:26:18:8a:b5:7a
#           WAN IP: 174.115.236.50
#           IF: enp2s0 ip-v4: 192.168.0.10 ip-v6-link: fe80::226:18ff:fe8a:b57a
#           ip-v6-global: fd00:8494:8c30:fac2:226:18ff:fe8a:b57a/64
#           ip-v6-global: 2607:fea8:c2a0:63:226:18ff:fe8a:b57a/64

}	#report_NETWORK()



report_HARDWARE()
{
echo "\n\n######################################################################################################\n####   HOST HARDWARE DETAILS"

COM="inxi ${OPTIONS} -s -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Sensors:   System Temperatures: cpu: 44.0C mobo: 44.0C
#           Fan Speeds (in rpm): cpu: 3245 sys-1: 0 sys-2: 0


COM="inxi ${OPTIONS} -B -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Battery    hidpp__0: charge: N/A condition: NA/NA Wh volts: NA model: Logitech Wireless Mouse M325 serial: 400a-7b-8b-e6-50 status: Discharging


COM="inxi ${OPTIONS} -M -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Machine:   Device: desktop Mobo: ASUSTeK model: M4A78-E v: Rev 1.xx serial: 101048580000313 BIOS: American Megatrends v: 2603 date: 04/13/2011


COM="inxi ${OPTIONS} -C -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#CPU:       Triple core AMD Phenom II X4 810 (-MCP-) arch: K10 rev.2 cache: 1536 KB flags: (lm nx sse sse2 sse3 sse4a svm) bmips: 15651
#           clock speeds: min/max: 800/2600 MHz 1: 1900 MHz 2: 1400 MHz 3: 1400 MHz


COM="inxi ${OPTIONS} -m -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Memory:    Used/Total: 1343.1/3683.4MB
#           Array-1 capacity: 8 GB devices: 4 EC: None
#           Device-1: DIMM0 size: 2 GB speed: 800 MT/s type: DDR (Synchronous) bus width: 64 bits manufacturer: N/A part: N/A serial: N/A
#           Device-2: DIMM1 size: 2 GB speed: 800 MT/s type: DDR (Synchronous) bus width: 64 bits manufacturer: N/A part: N/A serial: N/A
#           Device-3: DIMM2 size: No Module Installed type: N/A
#           Device-4: DIMM3 size: No Module Installed type: N/A


COM="inxi ${OPTIONS} -G -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Graphics:  Card: Advanced Micro Devices [AMD/ATI] RS780D [Radeon HD 3300] bus-ID: 01:05.0 chip-ID: 1002:9614
#           Display Server: X.Org 1.20.5 drivers: ati,radeon (unloaded: modesetting,fbdev,vesa) Resolution: 1440x900@59.89hz
#           OpenGL: renderer: AMD RS780 (DRM 2.50.0 / 5.3.0-53-generic, LLVM 9.0.0) version: 3.3 Mesa 19.2.8 (compat-v: 3.0) Direct Render: Yes


COM="inxi ${OPTIONS} -A -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Audio:     Card-1 Advanced Micro Devices [AMD/ATI] RS780 HDMI Audio [Radeon 3000/3100 / HD 3200/3300] driver: snd_hda_intel bus-ID: 01:05.1 chip-ID: 1002:960f Sound: ALSA v: k5.3.0-53-generic
#           Card-2 Advanced Micro Devices [AMD/ATI] SBx00 Azalia (Intel HDA) driver: snd_hda_intel bus-ID: 00:14.2 chip-ID: 1002:4383


COM="inxi ${OPTIONS} -N -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Network:   Card: Qualcomm Atheros AR8121/AR8113/AR8114 Gigabit or Fast Ethernet driver: ATL1E port: dc00 bus-ID: 02:00.0 chip-ID: 1969:1026


COM="inxi ${OPTIONS} -Dd -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Drives:    HDD Total Size: 4620.9GB (42.9% used)
#           ID-1: /dev/sda model: WDC_WD20EZRX size: 2000.4GB serial: WD-WCC300611350 temp: 39C
#           ID-2: /dev/sdb model: WDC_WD5000AAKS size: 500.1GB serial: WD-WMAWF0060756 temp: 39C
#           ID-3: /dev/sdc model: WDC_WD20EZRZ size: 2000.4GB serial: WD-WCC4N4HJ7YCE temp: 37C
#           ID-4: /dev/sdd model: WDC_WD1200JB size: 120.0GB serial: WD-WCALA1747715 temp: 46C
#           Floppy-1: /dev/fd0
#           Optical-1: /dev/sr0 model: ASUS DRW-24F1ST   c rev: 1.00 dev-links: cdrom,cdrw,dvd,dvdrw
#           Features: speed: 48x multisession: yes audio: yes dvd: yes rw: cd-r,cd-rw,dvd-r,dvd-ram state: running


COM="inxi ${OPTIONS} -plu -xxx"
echo "\n----------------------------------------------------------------------\n COMMAND: '${COM}'" ; ${COM}
#Partition: ID-1: / size: 288G used: 54G (20%) fs: ext4 dev: /dev/sda1 label: DB001_F1 uuid: f56b6086-229d-4c17-8a5b-e68de1a4e73d
#           ID-2: /site/DB003_F1 size: 454G used: 21G (5%) fs: ext4 dev: /dev/sdb1 label: DB003_F1 uuid: 12d9cfcc-8da0-4ba6-a7f8-cd08870c2890
#           ID-3: /site/DB004_F1 size: 108G used: 8.3G (9%) fs: ext4 dev: /dev/sdd1 label: DB004_F1 uuid: 5f3757ca-7b47-407b-b0e9-6c5ae68106e3
#           ID-4: /site/DB002_F1 size: 295G used: 6.9G (3%) fs: ext4 dev: /dev/sdc1 label: DB002_F1 uuid: 0aa50783-954b-4024-99c0-77a2a54a05c2
#           ID-5: /site/DB002_F2 size: 1.5T used: 985G (68%) fs: ext4 dev: /dev/sdc3 label: DB002_F2 uuid: 7e10c52e-fe20-497b-beab-f67e75cf7d83
#           ID-6: /DB001_F2 size: 289G used: 73G (27%) fs: ext4 dev: /dev/sda7 label: DB001_F2 uuid: 7e9a663e-ff1d-4730-8544-c37519056b6f
#           ID-7: /DB001_F3 size: 289G used: 237G (87%) fs: ext4 dev: /dev/sda8 label: DB001_F3 uuid: 4f7d4192-b136-4a94-b06b-736f76155816
#           ID-8: /DB001_F4 size: 289G used: 242G (89%) fs: ext4 dev: /dev/sda9 label: DB001_F4 uuid: 7f37ffd4-779a-46c6-b440-f384fb75eb98
#           ID-9: /DB001_F5 size: 193G used: 30G (17%) fs: ext4 dev: /dev/sda12 label: DB001_F5 uuid: 17a1582c-7dd2-4ea4-bc69-db6d2317ff92
#           ID-10: /DB001_F6 size: 193G used: 161G (88%) fs: ext4 dev: /dev/sda13 label: DB001_F6 uuid: f255b2a2-8549-451f-9b97-f6ebe66c8d3a
#           ID-11: /DB001_F7 size: 289G used: 18G (7%) fs: ext4 dev: /dev/sda14 label: DB001_F7 uuid: 58f622cd-2841-4967-8def-86dd38192769
#           ID-12: swap-1 size: 1.04GB used: 0.00GB (0%) fs: swap dev: /dev/sda5 label: DB001_S3 uuid: c16e9d3b-0ea5-4c2b-808b-9962509f04dd
#           ID-13: swap-2 size: 1.04GB used: 0.00GB (0%) fs: swap dev: /dev/sda6 label: DB001_S4 uuid: f9441354-ee42-4cef-912e-82e10a3d18af
#           ID-14: swap-3 size: 4.29GB used: 0.00GB (0%) fs: swap dev: /dev/sdc2 label: DB002_S1 uuid: 7dd23169-56c6-4c2c-afbb-9e75d4de7652
#           ID-15: swap-4 size: 1.04GB used: 0.00GB (0%) fs: swap dev: /dev/sda4 label: DB001_S2 uuid: 227afe2c-ee1a-4065-bc9d-24040ea01849
#           ID-16: swap-5 size: 2.15GB used: 0.00GB (0%) fs: swap dev: /dev/sdd2 label: DB004_S1 uuid: a7de6699-4a57-4ed7-b3df-a1641b1c6ff9
#           ID-17: swap-6 size: 4.29GB used: 0.00GB (0%) fs: swap dev: /dev/sdb2 label: DB003_S1 uuid: 48245d59-d265-459d-860c-d0caaf616fa7
#           ID-18: swap-7 size: 1.04GB used: 0.00GB (0%) fs: swap dev: /dev/sda3 label: DB001_S1 uuid: c37e53cd-5882-401c-8ba3-172531a082e9
#           ID-19: swap-8 size: 1.04GB used: 0.00GB (0%) fs: swap dev: /dev/sda10 label: DB001_S5 uuid: 3b9a2c7a-67d4-4de7-ae66-214937dc47f4
#           ID-20: swap-9 size: 1.04GB used: 0.00GB (0%) fs: swap dev: /dev/sda11 label: DB001_S6 uuid: 78b04c8c-8ace-4b46-817d-7059aa1668b7

}	#report_HARDWARE()


#123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+

COLS_MAX_CONSOL=155 ; export COLS_MAX_CONSOL

OPTIONS="-y 255 -c 0"
REPORT=`basename "$0" ".sh" `.out

{
	report_OS
	report_NETWORK
	report_HARDWARE
} 2>&1 | tee "${REPORT}"

echo "" ; ls -l "${REPORT}"


exit 0
exit 0
exit 0
