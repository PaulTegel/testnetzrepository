#!/bin/bash

echo ""
echo ""
echo "remove ntp-ti.ntpd"
docker rmi docker-registry:50000/testnetz/ntp-ti.ntpd
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove crl-ti.httpd"
docker rmi docker-registry:50000/testnetz/crl-ti.httpd
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove ksr-ti.java"
docker rmi docker-registry:50000/testnetz/ksr-ti.java
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove vsdm-ti-offen-fd.httpd"
docker rmi docker-registry:50000/testnetz/vsdm-ti-offen-fd.httpd 
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove ti-konzentrator.dnsmasq"
docker rmi docker-registry:50000/testnetz/ti-konzentrator.dnsmasq
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove ti-konzentrator.strongswan"
docker rmi docker-registry:50000/testnetz/ti-konzentrator.strongswan
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove router.nat"
docker rmi docker-registry:50000/testnetz/router.nat
echo "deleted"

sleep 2


echo ""
echo ""
echo "remove wp-bn.bestandsnetz"
docker rmi docker-registry:50000/testnetz/wp-bn.bestandsnetz
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove dns-bestd-net.dnsmasq"
docker rmi docker-registry:50000/testnetz/dns-bestd-net.dnsmasq
echo "deleted"

sleep 2

echo ""
echo ""
echo "remove router.dnsmasq"
docker rmi docker-registry:50000/testnetz/router.dnsmasq
echo "deleted"

echo ""
echo ""
echo "fertig"

