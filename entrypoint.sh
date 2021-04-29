#!/bin/sh

set -e
if [ -z "${LDAP_PASSWORD}" ]; then
    echo "environment variable LDAP_PASSWORD is empty"
    exit 1
fi
ENCRYPTED_PASSWORD=`slappasswd -h {SSHA} -s ${LDAP_PASSWORD}`

ENCRYPTED_PASSWORD=${ENCRYPTED_PASSWORD} confd -onetime -backend env

if [ "$?" -ne "0" ];then
    exit $?
fi

exec "$@"
