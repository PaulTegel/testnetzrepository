#!/bin/bash

/etc/init.d/dnsmasq start
inotifywait -m -e create /etc/dnsmasq/ --format "%f" | while read res
do 
    file=$(echo $res)
    if [ "reload" == $file ]; then
        /usr/local/bin/dnsmasq.sh
    fi
done

