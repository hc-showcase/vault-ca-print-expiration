#!/bin/sh
#set -x

function find_entity_aliases() {
    echo "- namespace: ${1}"

    # List Entity Alias by ID
    entity_aliases=$(curl -s -XLIST --header "X-Vault-Namespace: ${1}" \
                            --header "X-Vault-Token: ${VAULT_TOKEN}" \
                            ${VAULT_ADDR}/v1/identity/entity-alias/id \
                            | jq -r '.data.keys')

    if [[ "$entity_aliases" == '' ]]; then
      #echo "Namespace $1 does not contain any entities"
      return
    fi

    echo "  entities:"

    # Fetch Entity details for each Alias ID
    # https://www.vaultproject.io/api-docs/secret/identity/entity-alias
    for e in $(echo ${entity_aliases[@]} | jq -r '.[]')
    do
      echo "    - id: $e"
      alias=$(curl -s --header "X-Vault-Namespace: ${1}" \
                      --header "X-Vault-Token: ${VAULT_TOKEN}" \
                      ${VAULT_ADDR}/v1/identity/entity-alias/id/$e \
                      | jq -r '.data')

      mount_path=$(echo $alias | jq -r '.mount_path')
      alias_name=$(echo $alias | jq -r '.name')
      # Entity ID to which this alias belongs to.
      canonical_id=$(echo $alias | jq -r '.canonical_id')

      echo "      mount_path: $mount_path"
      echo "      alias_name: $alias_name"
      echo "      canonical_id: $canonical_id"
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

  find_entity_aliases "${2}"
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
find_entity_aliases "root/"

