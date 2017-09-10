FROM debian:jessie

LABEL maintainer "jschumann"

# Stripped down copy of https://github.com/phusion/baseimage-docker/

# Execute all packages installations in a single RUN step in order to avoid
# unecessary image layers with intermediate files.
COPY ./bd_build/ /bd_build/

RUN /bd_build/prepare.sh && \
	/bd_build/system_services.sh && \
	/bd_build/utilities.sh && \
    /bd_build/testnetz_utilities.sh && \
	/bd_build/cleanup.sh


# Expose SSH port. SSH gets installed by system_services.sh
EXPOSE 22	

# Standard root password
RUN echo "root:123456" | chpasswd


ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Common networking tasks
COPY bin/pipework /usr/local/bin/
COPY bin/testnetz_networking.sh /etc/my_init.d/01_testnetz_networking.sh
RUN chmod +x /etc/my_init.d/01_testnetz_networking.sh

# Health checks
COPY bin/testnetz_healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/testnetz_healthcheck.sh
HEALTHCHECK --interval=5s \
    --timeout=10s \
    --retries=1 \
    CMD /usr/local/bin/testnetz_healthcheck.sh


CMD ["/sbin/my_init", "--enable-insecure-key"]

COPY .bashrc /root/.bashrc

# Note: The invocation of ubuntu.sh provides a reliable 'tcpdump'
#       invocation/execution in ubuntu (container) environment
COPY bin/ubuntu.sh /tmp/ubuntu.sh
RUN chmod +x /tmp/ubuntu.sh
RUN exec /tmp/ubuntu.sh
