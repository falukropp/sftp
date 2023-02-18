FROM alpine:3.17.2
LABEL MAINTAINER="FALUKROPP" \
      "GitHub Link"="https://github.com/falukropp"

# Steps done in one RUN layer:
# - Install packages
# - Fix default group (1000 does not exist)
# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
RUN apk add --no-cache bash shadow procps whois openssh-sftp-server mysecureshell rsyslog && \
    chmod 4755 /usr/bin/mysecureshell && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key* && \
    mkdir -p /etc/rsyslog.d

COPY files/rsyslog.conf /etc/rsyslog.conf
COPY files/sshd_config /etc/ssh/sshd_config
COPY files/create-sftp-user /usr/local/bin/
COPY files/entrypoint /

EXPOSE 22

ENTRYPOINT ["/entrypoint"]