#!/bin/bash

MY_PATH=$(dirname $(dirname $(realpath $0)))

$MY_PATH/dnsmasq.sh stop-rm
$MY_PATH/dnsmasq.sh -f run
