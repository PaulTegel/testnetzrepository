#!/bin/sh
set -e
exec /usr/sbin/dnsmasq -dddd --conf-dir=/etc/dnsmasq.d --dhcp-lease-max=126
