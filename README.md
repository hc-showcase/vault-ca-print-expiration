# Print CA Expiration Dates

This script iterates over all PKI engines in Vault, extracts the CA and prints it expiration date.

Something like this:
```
mkaesz@arch ~/w/ca-monitoring (master)> bash print_CA_expiration.sh
CA stored in engine pki/ in namespace root/ has the following expiration date: notAfter=May  7 13:10:16 2022 GMT
CA stored in engine pki2/ in namespace root/ has the following expiration date: notAfter=May  7 13:10:16 2022 GMT
CA stored in engine pki3/ in namespace root/ has the following expiration date: notAfter=May  7 13:10:16 2022 GMT
PKI engine pki/ in namespace ns1/ does not contain a CA.
PKI engine pki2/ in namespace ns1/ does not contain a CA.
PKI engine pki1/ in namespace ns2/ns3/ does not contain a CA.
PKI engine pki2/ in namespace ns2/ns3/ does not contain a CA.
PKI engine pki/ in namespace ns2/ does not contain a CA.
PKI engine pki2/ in namespace ns2/ does not contain a CA.
```

# Group Inventory

This script provides a list of all the groups in Vault including some
information about the group alias, if it is an external group.

Example:
```
$ bash print_groups.sh | yq
- namespace: tenant/sub-tenant/sub-sub-tenant/sub-sub-sub-tenant/
  groups:
- namespace: tenant/sub-tenant/sub-sub-tenant/
  groups:
- namespace: tenant/sub-tenant/
  groups:
- namespace: tenant/
  groups:
    - name: testgroup-internal
      type: internal
      alias_name: null
      mount_accessor: null
      mount_path: null
      mount_type: null
      policies: ["default"]
- namespace: root/
  groups:
    - name: oidc-testgroup-external
      type: external
      alias_name: testgroup
      mount_accessor: auth_oidc_88c50556
      mount_path: auth/oidc/
      mount_type: oidc
      policies: null
    - name: ldap-testgroup-external
      type: external
      alias_name: testgroup
      mount_accessor: auth_ldap_5f3809e9
      mount_path: auth/ldap/
      mount_type: ldap
      policies: null
```

# Identity Inventory

This script outputs all Entities and Entity Aliases inside Vault
