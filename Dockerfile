FROM balenalib/rpi-raspbian:latest

# Connect to below URL to have access to the version number of the latest stable UniFi Network Controller (here is 5.10.17)
# https://www.ui.com/download/unifi
ENV UNIFI_VERSION 5.10.17

RUN apt-key adv --no-tty --keyserver keyserver.ubuntu.com --recv C0A52C50 && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" \
    > /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" \
    >> /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

# Install java before unifi so a controller update doesn't force
# a rebuild/redownload of java
RUN apt-get update && apt-get install -y --no-install-recommends \
    oracle-java8-installer=$(curl -sk https://launchpad.net/~webupd8team/+archive/ubuntu/java|grep -A3 -m1 oracle-java8-installer|tail -1|tr -d ' ') \
    oracle-java8-set-default \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/oracle-jdk8-installer

RUN apt-get update && apt-get install -y --no-install-recommends wget execstack && \
      mkdir -p /tmp/build && \
      cd /tmp/build && \
      wget https://dl.ubnt.com/unifi/${UNIFI_VERSION}/unifi_sysvinit_all.deb && \
      dpkg --install unifi_sysvinit_all.deb ; \
      apt-get install -f && \
      rm -rf /var/lib/apt/lists/* && \
      rm -rf /tmp/build

RUN ln -s /var/lib/unifi /usr/lib/unifi/data \
    && execstack -c /usr/lib/unifi/lib/native/Linux/armv7/libubnt_webrtc_jni.so
EXPOSE 8080/tcp 8081/tcp 8443/tcp 8843/tcp 8880/tcp 3478/udp

WORKDIR /var/lib/unifi

ENTRYPOINT ["/usr/bin/java", "-Xmx1024M", "-jar", "/usr/lib/unifi/lib/ace.jar"]
CMD ["start"]
