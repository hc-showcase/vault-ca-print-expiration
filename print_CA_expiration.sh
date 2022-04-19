#!/bin/sh
#set -x

function find_pki_engines() {
pki_engines=$(curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --header "X-Vault-Namespace: ${1}" \
    ${VAULT_ADDR}/v1/sys/mounts | \
    jq -r '.data | to_entries[] | select(.value.type=="pki").key')

for engine in $pki_engines; do
    result=$(curl -s --header "X-Vault-Namespace: ${1}" \
	    ${VAULT_ADDR}/v1/${engine}ca/pem)

    if [[ "$result" == '' ]]; then
	echo "PKI engine $engine in namespace $1 does not contain a CA."
    else
        echo "CA stored in engine $engine in namespace $1 has the following expiration date: $(openssl x509 -enddate -noout <<< "$result")"
    fi
done
}

function go_one_ns_deeper() {
for ns in "$1"
do
    namespaces_arr=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" \
	--header "X-Vault-Namespace: ${2}" -X LIST \
	"${VAULT_ADDR}/v1/sys/namespaces/" | \
	jq -r '.data.keys' | sed 's/[],[]//g'` )

    if [[ "$namespaces_arr" != "null" ]]; then
        for sub_namespace in "${namespaces_arr[@]}"
        do
            go_one_ns_deeper "${sub_namespace//\"}" "$2${sub_namespace//\"}"
        done
    fi
    find_pki_engines "${2}"
done
}

root_namespace_arr=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" -X LIST \
	"${VAULT_ADDR}/v1/sys/namespaces/" | jq .data.keys | sed 's/[],[]//g' `) # Get the namespace list under / in a sanitised bash array

# Root namespace is weired... threfore handling it separately and not as part of the array
find_pki_engines "root/"

for ns in "${root_namespace_arr[@]}"
do
    go_one_ns_deeper "${ns//\"}" "${ns//\"}"
done
