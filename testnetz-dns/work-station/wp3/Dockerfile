FROM docker-registry:5000/testnetz/base-image
LABEL maintainer "paw"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    isc-dhcp-client \
    openresolv

#COPY dhcp.sh /etc/my_init.d/dhcp.sh
#RUN chmod +x /etc/my_init.d/dhcp.sh


#COPY resolv.conf /etc/resolv.conf


COPY run.sh     /etc/my_init.d/run.sh
RUN chmod +x    /etc/my_init.d/run.sh

