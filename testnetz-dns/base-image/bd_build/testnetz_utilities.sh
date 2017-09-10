#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

echo "deb http://deb.debian.org/debian jessie-backports main" > \
    /etc/apt/sources.list.d/backports.list

apt-get update

${minimal_apt_get_install} -t jessie-backports \
        openjdk-8-jdk 

${minimal_apt_get_install} net-tools \
    iputils-arping \
    iputils-ping \
    python \
    tcpdump \
    traceroute \
    wget \
    dnsutils

# timezone
echo "Europe/Berlin" > /etc/timezone 
dpkg-reconfigure -f noninteractive tzdata

