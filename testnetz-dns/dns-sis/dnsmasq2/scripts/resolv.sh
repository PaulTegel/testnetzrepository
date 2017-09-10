#!/bin/bash

MY_PATH=$(dirname $(dirname $(realpath $0)))

sleep 2
$MY_PATH/dnsmasq.sh resolv
