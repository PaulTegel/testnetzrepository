#!/bin/sh

# Note: The handling of this script does effect in Ubuntu (container)
#       environment only; it solves a specific problem for successfully
#       running 'tcpdump' command!
#       (problem: /usr/sbin/tcpdump: error while loading shared libraries: 
#                 libcrypto.so.1.0.0: cannot open shared object file: Permission denied

/bin/uname -a |/bin/grep "Ubuntu"
if [ $? -eq 0 ]; then
   /bin/mv /usr/sbin/tcpdump /usr/bin/tcpdump
   /bin/ln -s /usr/bin/tcpdump /usr/sbin/tcpdump
fi
