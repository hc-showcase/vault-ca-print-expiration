#!/bin/sh
set -x

pki_engines=$(curl -s --header "X-Vault-Token: root" \
	http://192.168.1.119:9201/v1/sys/mounts | \
	jq -r '.data | to_entries[] | select(.value.type=="pki") | .key')

for engine in $pki_engines; do
	curl -s http://192.168.1.119:9201/v1/${engine}ca/pem | \
		openssl x509 -enddate -noout;
done;

