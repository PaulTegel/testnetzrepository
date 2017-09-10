FROM docker-registry:5000/testnetz/base-image
LABEL maintainer "paw"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dnsmasq \
    dnsutils \
    openresolv

# DHCP daemon
COPY dnsmasq.conf    /etc/dnsmasq.d/dnsmasq.conf
COPY dnsmasq.conf    /etc/dnsmasq.conf

#COPY dnsmasq-runit.sh /etc/service/dnsmasq/run
#RUN chmod +x /etc/service/dnsmasq/run

COPY dnsmasq-runit.sh /etc/my_init.d/run

COPY hosts /etc/hosts

COPY resolv.conf /etc/resolv.conf
COPY resolv.conf /etc/resolv.conf
