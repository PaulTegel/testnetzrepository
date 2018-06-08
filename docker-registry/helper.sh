#!/bin/bash

#docker tag  docker-registry:5000/testnetz/work-station.wp3   docker-registry:50000/testnetz/work-station.wp3           
#docker push docker-registry:50000/testnetz/work-station.wp3


#docker tag  docker-registry:5000/testnetz/ocsp-ti.java   docker-registry:50000/testnetz/ocsp-ti.java               
#docker push docker-registry:50000/testnetz/ocsp-ti.java


#docker tag  docker-registry:5000/testnetz/tsl-ti  docker-registry:50000/testnetz/tsl-ti                      
#docker push docker-registry:50000/testnetz/tsl-ti


#docker tag  docker-registry:5000/testnetz/register-ti.java  docker-registry:50000/testnetz/register-ti.java            
#docker push docker-registry:50000/testnetz/register-ti.java


#docker tag  docker-registry:5000/testnetz/trust-anchor.httpd  docker-registry:50000/testnetz/trust-anchor.httpd          
#docker push docker-registry:50000/testnetz/trust-anchor.httpd


#docker tag  docker-registry:5000/testnetz/intermediaer-ti.httpd  docker-registry:50000/testnetz/intermediaer-ti.httpd       
#docker push docker-registry:50000/testnetz/intermediaer-ti.httpd


#docker tag  docker-registry:5000/testnetz/sis-webserver.httpd   docker-registry:50000/testnetz/sis-webserver.httpd        
#docker push docker-registry:50000/testnetz/sis-webserver.httpd


#docker tag  docker-registry:5000/testnetz/dns-sis.bind9   docker-registry:50000/testnetz/dns-sis.bind9              
#docker push docker-registry:50000/testnetz/dns-sis.bind9


#docker tag  docker-registry:5000/testnetz/sis-konzentrator.dnsmasq   docker-registry:50000/testnetz/sis-konzentrator.dnsmasq   
#docker push docker-registry:50000/testnetz/sis-konzentrator.dnsmasq


#docker tag  docker-registry:5000/testnetz/sis-konzentrator.strongswan  docker-registry:50000/testnetz/sis-konzentrator.strongswan 
#docker push docker-registry:50000/testnetz/sis-konzentrator.strongswan


#docker tag  docker-registry:5000/testnetz/dns-public.bind9   docker-registry:50000/testnetz/dns-public.bind9           
#docker push docker-registry:50000/testnetz/dns-public.bind9


#docker tag  docker-registry:5000/testnetz/dns-ti.bind9  docker-registry:50000/testnetz/dns-ti.bind9                
#docker push docker-registry:50000/testnetz/dns-ti.bind9


#docker tag  docker-registry:5000/testnetz/vsdm-ti.httpd   docker-registry:50000/testnetz/vsdm-ti.httpd              
#docker push docker-registry:50000/testnetz/vsdm-ti.httpd

echo ""
echo "import ntp-ti.ntpd"
docker tag  docker-registry:5000/testnetz/ntp-ti.ntpd docker-registry:50000/testnetz/ntp-ti.ntpd               
docker push docker-registry:50000/testnetz/ntp-ti.ntpd
echo "import ntp-ti.ntpd ende"

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/crl-ti.httpd    docker-registry:50000/testnetz/crl-ti.httpd              
docker push docker-registry:50000/testnetz/crl-ti.httpd

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/ksr-ti.java    docker-registry:50000/testnetz/ksr-ti.java               
docker push docker-registry:50000/testnetz/ksr-ti.java

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/vsdm-ti-offen-fd.httpd    docker-registry:50000/testnetz/vsdm-ti-offen-fd.httpd     
docker push docker-registry:50000/testnetz/vsdm-ti-offen-fd.httpd 

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/ti-konzentrator.dnsmasq    docker-registry:50000/testnetz/ti-konzentrator.dnsmasq   
docker push docker-registry:50000/testnetz/ti-konzentrator.dnsmasq

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/ti-konzentrator.strongswan    docker-registry:50000/testnetz/ti-konzentrator.strongswan
docker push docker-registry:50000/testnetz/ti-konzentrator.strongswan

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/router.nat   docker-registry:50000/testnetz/router.nat                 
docker push docker-registry:50000/testnetz/router.nat

sleep 2


echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/wp-bn.bestandsnetz   docker-registry:50000/testnetz/wp-bn.bestandsnetz         
docker push docker-registry:50000/testnetz/wp-bn.bestandsnetz

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/dns-bestd-net.dnsmasq  docker-registry:50000/testnetz/dns-bestd-net.dnsmasq       
docker push docker-registry:50000/testnetz/dns-bestd-net.dnsmasq

sleep 2

echo ""
echo "import "
docker tag  docker-registry:5000/testnetz/router.dnsmasq   docker-registry:50000/testnetz/router.dnsmasq             
docker push docker-registry:50000/testnetz/router.dnsmasq


