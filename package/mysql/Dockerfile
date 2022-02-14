FROM ubuntu:20.04
ARG CN_MIRROR
ARG PROXY
ARG MYSQL_APT_CONF_VERSION=0.8.22-1
ENV DEBIAN_FRONTEND=noninteractive
RUN [ -z "${CN_MIRROR}" ] || sed -i "s;archive.ubuntu.com;mirrors.aliyun.com;g" /etc/apt/sources.list &&\
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt -y install tzdata&&\
    apt install -y wget lsb-release gnupg unixodbc ldap-utils dpkg-dev &&\
    wget https://repo.mysql.com//mysql-apt-config_${MYSQL_APT_CONF_VERSION}_all.deb -O /tmp/mysql-apt-config_${MYSQL_APT_CONF_VERSION}_all.deb &&\
    echo "mysql-apt-config	mysql-apt-config/select-product	select	Ok" | debconf-set-selections &&\
    dpkg -i /tmp/mysql-apt-config_${MYSQL_APT_CONF_VERSION}_all.deb &&\
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
COPY bin/confd /usr/local/bin/confd
COPY bin/openldap/* /usr/local/bin/
ADD dist/openldap dist/openldap
ADD odbc.toml slapd.toml /etc/confd/conf.d/
ADD odbc.tmpl slapd.tmpl /etc/confd/templates/
ADD odbcinst.ini /etc/odbcinst.ini
ADD entrypoint.sh /
ENV LDAP_PASSWORD=root DB_NAME=ldap DB_USER=root DB_PORT=3306 DN_SUFFIX=dc=example,dc=com DN_ROOT=cn=root,dc=example,dc=com
EXPOSE 389
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "slapd", "-d", "5", "-h", "ldap:///", "-f", "/etc/openldap/slapd.conf" ]
