FROM alpine AS builder
RUN apk add git ca-certificates > /dev/null 2>/dev/null
RUN git clone https://github.com/pivpn/pivpn.git /clone

FROM debian:bullseye-20230109-slim

RUN adduser --home /home/pivpn --disabled-password pivpn \
    && echo "deb http://deb.debian.org/debian buster-backports main non-free" >> /etc/apt/sources.list \
    && apt-get update && apt-get install -y -f --no-install-recommends wireguard-tools qrencode gnupg \
    openvpn grepcidr expect curl nano sudo bsdmainutils bash-completion cron ca-certificates iproute2 \
    net-tools iptables-persistent apt-transport-https whiptail dnsutils grep dhcpcd5 iptables-persistent \
    python3.9 python3-pip 

WORKDIR /home/pivpn
COPY sh/ /usr/local/bin/
COPY crontab /etc/cron.d/update
COPY  --from=builder /clone /usr/local/src/pivpn
COPY run .

RUN apt-get update
# Only for debugging purposes!
RUN apt-get install -y -f openssh-server
    
RUN chmod 0644 /etc/cron.d/update && crontab /etc/cron.d/update \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* /etc/pivpn/openvpn/* /etc/openvpn/* /etc/wireguard/* /tmp/* || true \
    && chmod +x /home/pivpn/run /usr/local/bin/* \
    && ln -s /usr/sbin/iptables /sbin/iptables && ln -s /usr/sbin/iptables-save /sbin/iptables-save

# Stupid workaround for this bug: https://github.com/pivpn/pivpn/discussions/1409
RUN sed -i 's/cd "${1}" || exit 1/while [ ! -d "${1}" ]; do sleep 1; done && cd "${1}"/g' /usr/local/src/pivpn/auto_install/install.sh

ENTRYPOINT ["./run"]
