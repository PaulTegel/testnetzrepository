#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

## Install init process.
cp /bd_build/bin/my_init /sbin/
mkdir -p /etc/my_init.d
mkdir -p /etc/container_environment
touch /etc/container_environment.sh
touch /etc/container_environment.json
chmod 700 /etc/container_environment

groupadd -g 8377 docker_env
chown :docker_env /etc/container_environment.sh /etc/container_environment.json
chmod 640 /etc/container_environment.sh /etc/container_environment.json
ln -s /etc/container_environment.sh /etc/profile.d/

## my_init requires python3
$minimal_apt_get_install python3

## Install runit.
$minimal_apt_get_install runit

## Install more progs
$minimal_apt_get_install mc
$minimal_apt_get_install dhcping
$minimal_apt_get_install nano
$minimal_apt_get_install ethtool
$minimal_apt_get_install nmap

## Install the SSH server.
[ "$DISABLE_SSH" -eq 0 ] && /bd_build/services/sshd/sshd.sh || true

