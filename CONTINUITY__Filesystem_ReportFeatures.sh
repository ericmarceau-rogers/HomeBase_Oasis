#!/bin/sh

### Provides details related to the filesystem
tune2fs -l /dev/sda12 | grep features

### Provides same resutls but with different prefix string.
###	NOTE:  'debugfs' is locked out from accessing the filesystem if rsync process is writing data on the partition
#debugfs -R features /dev/sda12

exit 0
exit 0
exit 0


