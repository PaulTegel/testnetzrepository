#!/bin/bash

if [ -f /etc/dnsmasq/reload ]; then
	rm /etc/dnsmasq/reload
	/etc/init.d/dnsmasq force-reload
fi
