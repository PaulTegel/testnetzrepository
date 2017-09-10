FROM docker-registry:5000/testnetz/base-image
LABEL maintainer "paw"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dnsmasq \
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


EXPOSE 53


#COPY entrypoint.sh     /etc/my_init.d/run.sh
#RUN chmod +x    /etc/my_init.d/run.sh

#CMD /usr/local/bin/entrypoint.sh

#CMD /bin/bash


RUN mkdir /etc/dnsmasq

#RUN echo "kill"

#COPY entrypoint.sh     /etc/my_init.d/run.sh

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY entrypoint.sh /etc/my_init.d/run.sh
RUN chmod +x /etc/my_init.d/run.sh