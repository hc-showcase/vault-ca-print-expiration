#!/bin/sh
#set -x

function find_engines() {
    # List Engines by Name
    # https://developer.hashicorp.com/vault/api-docs/system/mounts#list-mounted-secrets-engines
    mounts=$(curl -s -XGET --header "X-Vault-Namespace: ${1}" \
                            --header "X-Vault-Token: ${VAULT_TOKEN}" \
                            ${VAULT_ADDR}/v1/sys/mounts \
                            | jq -r '.data')

    if [[ "$mounts" == '' ]]; then
      echo "Namespace $1 does not contain any mount points."
      return
    fi

    # Read details such as mount type for each mount
    for m in $(echo ${mounts[@]} | jq -r 'keys[]')
    do
      mount_type=$(echo $mounts | jq -r --arg mount $m '.[$mount].type')
      echo "- namespace: ${1}"
      echo "  engine_path: $m"
      echo "  engine_type: $mount_type"
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

  find_engines "${2}"
done
}

if [ -z "$VAULT_TOKEN" ]
then
    echo "\$VAULT_TOKEN must be set." >&2
  exit -1
fi

if [ -z "$VAULT_ADDR" ]
then
    echo "\$VAULT_ADDR must be set." >&2
  exit -1
fi

if [ -z jq ]
then
    echo "jq must be installed" >&2
  exit -1
fi

if [ -z sed ]
then
    echo "sed must be installed" >&2
  exit -1
fi

root_namespace_arr=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" -X LIST \
  "${VAULT_ADDR}/v1/sys/namespaces/" | jq .data.keys | sed 's/[],[]//g' `) # Get the namespace list under / in a sanitised bash array

for ns in "${root_namespace_arr[@]}"
do
  go_one_ns_deeper "${ns//\"}" "${ns//\"}"
done

# Root namespace is weired... threfore handling it separately and not as part of the array
find_engines "root/"
