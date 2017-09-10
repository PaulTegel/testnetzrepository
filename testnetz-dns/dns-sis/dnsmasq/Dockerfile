FROM debian

RUN apt-get update

RUN apt-get install -y dnsmasq \
    inotify-tools \
    mc \
    dhcping \
    nano \
    ethtool \
    nmap \
    net-tools \
    iputils-arping \
    iputils-ping \
    python \
    tcpdump \
    traceroute \
    wget \
    dnsutils


RUN echo "bind-interfaces\nconf-dir=/etc/dnsmasq/conf.d\nresolv-file=/etc/dnsmasq/resolv.dnsmasq.conf\nuser=root" >> /etc/dnsmasq.conf

COPY files/dnsmasq.sh /usr/local/bin/dnsmasq.sh
#ADD files/entrypoint.sh /usr/local/bin/entrypoint.sh

#VOLUME ['/etc/dnsmasq']

#CMD /usr/local/bin/entrypoint.sh

EXPOSE 53
