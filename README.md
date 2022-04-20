This script iterates over all PKI engines in Vault, extracts the CA and prints it expiration date.


Something likes this:
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
