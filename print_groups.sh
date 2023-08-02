#!/bin/sh
#set -x

function find_groups() {
    echo "- namespace: ${1}"

    # List Groups by Name
    # https://www.vaultproject.io/api-docs/secret/identity/group#list-groups-by-name
    groups=$(curl ${VAULT_SKIP_VERIFY:+-k} -s -XLIST --header "X-Vault-Namespace: ${1}" \
                            --header "X-Vault-Token: ${VAULT_TOKEN}" \
                            ${VAULT_ADDR}/v1/identity/group/name \
                            | jq -r '.data.keys')

    if [[ "$groups" == '' ]]; then
      #echo "Namespace $1 does not contain any groups."
      return
    fi

    #echo "  groups: ${groups[@]}"
    echo "  groups:"

    # Read Group and Aliases for each Group
    for g in $(echo ${groups[@]} | jq -r '.[]')
    do
      echo "    - name: $g"
      group=$(curl ${VAULT_SKIP_VERIFY:+-k} -s --header "X-Vault-Namespace: ${1}" \
                      --header "X-Vault-Token: ${VAULT_TOKEN}" \
                      ${VAULT_ADDR}/v1/identity/group/name/$g \
                      | jq -r '.data')

      alias=$(echo $group | jq -r '.alias')
      alias_name=$(echo $alias | jq -r '.name')
      policies=$(echo $group | jq -r '.policies')
      group_type=$(echo $group | jq -r '.type')

      echo "      type: $group_type"
      echo "      alias_name: $alias_name"
      echo -n "      mount_accessor: "
      echo $alias | jq -r '.mount_accessor'
      echo -n "      mount_path: "
      echo $alias | jq -r '.mount_path'
      echo -n "      mount_type: "
      echo $alias | jq -r '.mount_type'
      echo "      policies: $policies"
    done
}

function go_one_ns_deeper() {
for ns in "$1"
do
  namespaces_arr=( `curl ${VAULT_SKIP_VERIFY:+-k} -s --header "X-Vault-Token: ${VAULT_TOKEN}" \
                            --header "X-Vault-Namespace: ${2}" -X LIST \
                            "${VAULT_ADDR}/v1/sys/namespaces/" | \
                            jq -r '.data.keys' | sed 's/[],[]//g'` )

  if [[ "$namespaces_arr" != "null" ]]; then
    for sub_namespace in "${namespaces_arr[@]}"
    do
      go_one_ns_deeper "${sub_namespace//\"}" "$2${sub_namespace//\"}"
    done
  fi

  find_groups "${2}"
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

root_namespace_arr=( `curl ${VAULT_SKIP_VERIFY:+-k} -s --header "X-Vault-Token: ${VAULT_TOKEN}" -X LIST \
  "${VAULT_ADDR}/v1/sys/namespaces/" | jq .data.keys | sed 's/[],[]//g' `) # Get the namespace list under / in a sanitised bash array

for ns in "${root_namespace_arr[@]}"
do
  go_one_ns_deeper "${ns//\"}" "${ns//\"}"
done

# Root namespace is weired... threfore handling it separately and not as part of the array
find_groups "root/"
