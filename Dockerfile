FROM ubuntu:18.04 AS builder
ENV HTTP_PROXY=${HTTP_PROXY} HTTPS_PROXY=${HTTPS_PROXY} NOPROXY=${NOPROXY}}
RUN touch /etc/apt/apt.conf.d/proxy.conf &&\
    [ -z "$HTTP_PROXY" ] || echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf &&\
    [ -z "$HTTPS_PROXY" ] || echo "Acquire::https::Proxy \"${HTTPS_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf &&\
    apt-get update && \
    apt-get install -y unixodbc make gcc groff ldap-utils unixodbc-dev curl debconf-utils &&\
    apt-get clean -y &&\
    rm -rf \
    /var/cache/debconf/* \
    /var/lib/apt/lists/* \
    /var/log/* \
    /tmp/* \
    /var/tmp/* &&\
    mkdir \ldap &&\
    curl -sSL https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.48.tgz | tar xzf - -C /ldap && mv ./ldap/openldap* /opt/openldap &&\
    cd /opt/openldap &&\
    ./configure --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --datadir=/usr/share --localstatedir=/var --mandir=/usr/share/man --infodir=/usr/share/info --enable-sql --disable-bdb --disable-ndb --disable-hdb --disable-dependency-tracking --silent &&\
    make depend && make && make install && mkdir /usr/local/var &&\
    curl -sSL https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64 > /usr/local/bin/confd && chmod +x /usr/local/bin/confd && mkdir -p /etc/confd/conf.d /etc/confd/templates

FROM ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
RUN export HTTP_PROXY=${HTTP_PROXY} && export HTTPS_PROXY=${HTTPS_PROXY} && export NOPROXY=${NOPROXY}} &&\
    touch /etc/apt/apt.conf.d/proxy.conf &&\
    [ -z "$HTTP_PROXY" ] || echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf &&\
    [ -z "$HTTPS_PROXY" ] || echo "Acquire::https::Proxy \"${HTTPS_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf &&\
    apt update &&\
    apt install -y wget lsb-release gnupg unixodbc ldap-utils dpkg-dev &&\
    wget https://repo.mysql.com//mysql-apt-config_0.8.17-1_all.deb -O /tmp/mysql-apt-config_0.8.17-1_all.deb &&\
    echo "mysql-apt-config	mysql-apt-config/select-product	select	Ok" | debconf-set-selections &&\
    dpkg -i /tmp/mysql-apt-config_0.8.17-1_all.deb &&\
    apt update &&\
    apt-get install -y mysql-connector-odbc &&\
    apt-get clean -y &&\
    rm -rf \
    /var/cache/debconf/* \
    /var/lib/apt/lists/* \
    /var/log/* \
    /tmp/* \
    /var/tmp/* &&\
    mkdir -p /usr/local/var /etc/confd/conf.d /etc/confd/templates
COPY --from=builder /usr/local/bin/confd /usr/local/bin/confd
COPY --from=builder /opt/openldap/servers/slapd/slap* /usr/local/bin/
COPY --from=builder /etc/openldap /etc/openldap
ADD odbc.toml slapd.toml /etc/confd/conf.d/
ADD odbc.tmpl slapd.tmpl /etc/confd/templates/
ADD odbcinst.ini /etc/odbcinst.ini
ADD entrypoint.sh /
ENV LDAP_PASSWORD=root DB_NAME=ldap DB_USER=root DB_PORT=3306 DN_SUFFIX=dc=example,dc=com DN_ROOT=cn=root,dc=example,dc=com
EXPOSE 389
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "slapd", "-d", "5", "-h", "ldap:///", "-f", "/etc/openldap/slapd.conf" ]
