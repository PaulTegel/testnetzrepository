FROM docker-registry:5000/testnetz/base-image
LABEL maintainer "paw"

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ntp

COPY ntp /etc/default/ntp
COPY ntp.conf /etc/

WORKDIR /
RUN git clone https://github.com/wolfcw/libfaketime.git
WORKDIR /libfaketime/src
RUN make install

COPY ntpd-runit.sh /etc/my_init.d/ntpd-runit.sh
RUN chmod +x /etc/my_init.d/ntpd-runit.sh
