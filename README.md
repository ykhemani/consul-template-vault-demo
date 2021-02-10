# consul-template-vault-demo

[consul-template-vault-demo.sh](consul-template-vault-demo.sh) writes some sample secrets to a [HashiCorp](https://hashicorp.com) [Vault](https://vaultproject.io) cluster at the path specified via `${KV}` and then renders them via a [consul-template](https://github.com/hashicorp/consul-template) template to a file.

## Prerequisites:
* Vault cluster that is running and accessible. You can run a Vault cluster [in dev mode](https://www.vaultproject.io/docs/concepts/dev-server) or via [https://github.com/ykhemani/vault-local](https://github.com/ykhemani/vault-local) if you don't have one running.
* Vault auth that allows you to:
  * write a policy
  * generate a token with that policy attached
  * enable a secret engine
  * write secrets to that path
  * disable the secret engine
  You can use the root token if you're running a dev or demo Vault server as described in prerequisite 1 above.
* Ability to write to your filesystem at `${CONSUL_TEMPLATE_TOP}`
* uuidgen in your path to enable us to write some sample secrets.

## Environment variables.

Set environment variables as follows to override defaults:

* `CONSUL_TEMPLATE_TOP` - path where we can write the consul-template config, logs, sample template and sample result.
* `VAULT_ADDR` - Vault Address.
* `KV` - path to mount kv-v2 secret engine (shouldn't already exist, and it will be cleaned up at the end of the script.

## Usage:
```
git clone https://github.com/ykhemani/consul-template-vault-demo.git
cd consul-template-vault-demo
export VAULT_TOKEN=<VAULT_TOKEN>
./consul-template-vault-demo.sh
```

## Sample output:
```
$ export VAULT_TOKEN=s.2ShigIEFbYElWa14Rh2SQhsE

$ ./consul-template-vault-demo.sh 
Creating CONSUL_TEMPLATE_TOP directory /tmp/data/consul-template if it doesn't already exist.

Wed Feb 10 13:30:18 UTC 2021 [INFO] Starting ./consul-template-vault-demo.sh
Wed Feb 10 13:30:18 UTC 2021 [INFO] Logging to /tmp/data/consul-template/consul-template-demo.log
Wed Feb 10 13:30:18 UTC 2021 [INFO] VAULT_ADDR is http://localhost:8200

Wed Feb 10 13:30:18 UTC 2021 [INFO] Creating policy consul-template-demo-policy
Success! Uploaded policy: consul-template-demo-policy

Wed Feb 10 13:30:18 UTC 2021 [INFO] Policy consul-template-demo-policy created as follows:
path "kv-v2-consul-template-demo/data/*" {
  capabilities = ["read"]
}

path "kv-v2-consul-template-demo/metadata/*" {
  capabilities = ["read"]
}

path "auth/token/*" {
  capabilities = ["create", "update"]
}

Wed Feb 10 13:30:18 UTC 2021 [INFO] Generating token with policy consul-template-demo-policy.

Wed Feb 10 13:30:18 UTC 2021 [INFO] Enabling kv-v2 secrets engine at kv-v2-consul-template-demo.
Success! Enabled the kv-v2 secrets engine at: kv-v2-consul-template-demo/

Wed Feb 10 13:30:19 UTC 2021 [INFO] Writing some secrets at kv-v2-consul-template-demo.
Key              Value
---              -----
created_time     2021-02-10T13:30:20.04791Z
deletion_time    n/a
destroyed        false
version          1
Secret at kv-v2-consul-template-demo/item-1 is 9A10B293-3516-4780-8348-431B081FC3E4

Key              Value
---              -----
created_time     2021-02-10T13:30:20.18791Z
deletion_time    n/a
destroyed        false
version          1
Secret at kv-v2-consul-template-demo/item-2 is F87573FB-4947-42C9-9ECD-63A3F94FBB73

Key              Value
---              -----
created_time     2021-02-10T13:30:20.310976Z
deletion_time    n/a
destroyed        false
version          1
Secret at kv-v2-consul-template-demo/item-3 is E88230A5-94BB-414F-BF03-7497E9790D0B


Wed Feb 10 13:30:20 UTC 2021 [INFO] Generating consul-template config: /tmp/data/consul-template/consul-template.hcl

Wed Feb 10 13:30:20 UTC 2021 [INFO] Generating template for consul-template: /tmp/data/consul-template/demo.tpl

Wed Feb 10 13:30:20 UTC 2021 [INFO] Running consul-template once. Template will be rendered to /tmp/data/consul-template/demo.txt.
2021/02/10 13:30:20.451806 [WARN] (clients) disabling vault SSL verification

Wed Feb 10 13:30:20 UTC 2021 [INFO] Template rendered as follows:
item-1: 9A10B293-3516-4780-8348-431B081FC3E4

item-2: F87573FB-4947-42C9-9ECD-63A3F94FBB73

item-3: E88230A5-94BB-414F-BF03-7497E9790D0B

Wed Feb 10 13:30:20 UTC 2021 [INFO] Cleaning up
Wed Feb 10 13:30:20 UTC 2021 [INFO] Disabling secrets engine mounted at kv-v2-consul-template-demo.
Success! Disabled the secrets engine (if it existed) at: kv-v2-consul-template-demo/
Wed Feb 10 13:30:20 UTC 2021 [INFO] Revoking token s.a0y8ucOCFZwCAazrcEDDhN9f
Success! Revoked token (if it existed)
Wed Feb 10 13:30:20 UTC 2021 [INFO] Deleting policy consul-template-demo-policy
Success! Deleted policy: consul-template-demo-policy

Wed Feb 10 13:30:20 UTC 2021 [INFO] Done!
```

## Samples of files written by `consul-template-vault-demo.sh`

* `consul-template.hcl`
```
$ cat /tmp/data/consul-template/consul-template.hcl 
vault {
  address     = "http://localhost:8200"
  # namespace = "ns1"
  token       = "s.a0y8ucOCFZwCAazrcEDDhN9f"
  # vault_agent_token_file = ""
  renew_token = false
}

template {
  source      = "/tmp/data/consul-template/demo.tpl"
  destination = "/tmp/data/consul-template/demo.txt"
  perms       = 0640
}
```

* `demo.tpl`
```
$ cat /tmp/data/consul-template/demo.tpl 
item-1: {{ with secret "kv-v2-consul-template-demo/item-1" }}{{ .Data.data.token }}{{ end }}

item-2: {{ with secret "kv-v2-consul-template-demo/item-2" }}{{ .Data.data.token }}{{ end }}

item-3: {{ with secret "kv-v2-consul-template-demo/item-3" }}{{ .Data.data.token }}{{ end }}
```

* `demo.txt`
```
$ cat /tmp/data/consul-template/demo.txt 
item-1: 9A10B293-3516-4780-8348-431B081FC3E4

item-2: F87573FB-4947-42C9-9ECD-63A3F94FBB73

item-3: E88230A5-94BB-414F-BF03-7497E9790D0B
```

* `consul-template-demo.log`
```
$ cat /tmp/data/consul-template/consul-template-demo.log 
Wed Feb 10 13:30:18 UTC 2021 [INFO] Starting ./consul-template-vault-demo.sh
Wed Feb 10 13:30:18 UTC 2021 [INFO] Logging to /tmp/data/consul-template/consul-template-demo.log
Wed Feb 10 13:30:18 UTC 2021 [INFO] VAULT_ADDR is http://localhost:8200
Wed Feb 10 13:30:18 UTC 2021 [INFO] Creating policy consul-template-demo-policy
Wed Feb 10 13:30:18 UTC 2021 [INFO] Policy consul-template-demo-policy created as follows:
Wed Feb 10 13:30:18 UTC 2021 [INFO] Generating token with policy consul-template-demo-policy.
Wed Feb 10 13:30:18 UTC 2021 [INFO] Enabling kv-v2 secrets engine at kv-v2-consul-template-demo.
Wed Feb 10 13:30:19 UTC 2021 [INFO] Writing some secrets at kv-v2-consul-template-demo.
Wed Feb 10 13:30:20 UTC 2021 [INFO] Generating consul-template config: /tmp/data/consul-template/consul-template.hcl
Wed Feb 10 13:30:20 UTC 2021 [INFO] Generating template for consul-template: /tmp/data/consul-template/demo.tpl
Wed Feb 10 13:30:20 UTC 2021 [INFO] Running consul-template once. Template will be rendered to /tmp/data/consul-template/demo.txt.
Wed Feb 10 13:30:20 UTC 2021 [INFO] Template rendered as follows:
Wed Feb 10 13:30:20 UTC 2021 [INFO] Cleaning up
Wed Feb 10 13:30:20 UTC 2021 [INFO] Disabling secrets engine mounted at kv-v2-consul-template-demo.
Wed Feb 10 13:30:20 UTC 2021 [INFO] Revoking token s.a0y8ucOCFZwCAazrcEDDhN9f
Wed Feb 10 13:30:20 UTC 2021 [INFO] Deleting policy consul-template-demo-policy
Wed Feb 10 13:30:20 UTC 2021 [INFO] Done!
```