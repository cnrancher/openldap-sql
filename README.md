# openldap-sql

This repo is to build a openldap docker image with sql backend. With confd, you can set sql related variables via environment variables.

Only mysql backend is current supportted in this repo. More backends will be added if needed.

## building images

The images can be built simply with `make` command. The build process is driven by [dapper](https://github.com/rancher/dapper).

The following environment variables can be set for make command.

|name|description|
|---|---|
|`CN_MIRROR`|To set ubuntu apt using aliyun apt mirror.|
|`PROXY`|The http proxy to curl/wget resources. This can be use in ci scripts manually.|
|`LDAP_VERSION`|The specific openldap version to be packaged into the docker image.|
|`CONFD_VERSION`|The specific confd version to be packaged into the docker image.|

With following command, you can build a openldap image with mysql backend.

```bash
CN_MIRROR=true make ci
```
