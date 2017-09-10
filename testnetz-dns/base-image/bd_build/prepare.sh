#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

## Prevent initramfs updates from trying to run grub and lilo.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189
export INITRD=no
mkdir -p /etc/container_environment
echo -n no > /etc/container_environment/INITRD


## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

apt-get update

## Install HTTPS support for APT.
$minimal_apt_get_install apt-transport-https ca-certificates

## Fix locale.
localename="en_US.UTF-8 UTF-8"
$minimal_apt_get_install locales
echo ${localename} >> /etc/locale.gen
locale-gen

update-locale LANG="${localename}" LC_CTYPE="${localename}"
echo -n "${localename}" > /etc/container_environment/LANG
echo -n "${localename}" > /etc/container_environment/LC_CTYPE
