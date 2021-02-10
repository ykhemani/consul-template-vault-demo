#!/bin/bash

# Quick script to write some secrets to a secret engine specified via ${KV}
# and then render them via a consul-template template.
# 
# Set environment variables as follows to override defaults:
# KV - path to mount kv-v2 secret engine (shouldn't already exist, 
# and it will be cleaned up at the end of this script).
#
# CONSUL_TEMPLATE_TOP - path where we can write the consul-template config,
# sample template and sample result.
#
# VAULT_ADDR - Vault cluster URL.
#
# Prerequisites:
# * Vault cluster that is running and accessible.
# * Vault auth that allows you to:
#   * write a policy
#   * generate a token with that policy attached
#   * enable a secret engine
#   * write secrets to that path
#   * disable the secret engine
# * Ability to write to path defined at ${CONSUL_TEMPLATE_TOP}
# * uuidgen in your path to enable us to write some sample secrets.


export KV=${KV:-kv-v2-consul-template-demo}
export CONSUL_TEMPLATE_TOP=${CONSUL_TEMPLATE_TOP:-/tmp/data/consul-template}
export VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200}

export CONSUL_TEMPLATE_CONFIG=${CONSUL_TEMPLATE_TOP}/consul-template.hcl
#export VAULT_AGENT_TOKEN_FILE=${CONSUL_TEMPLATE_TOP}/token
export SAMPLE_TEMPLATE=${CONSUL_TEMPLATE_TOP}/demo.tpl
export SAMPLE_RESULT=${CONSUL_TEMPLATE_TOP}/demo.txt

export CONSUL_TEMPLATE_DEMO_POLICY=${CONSUL_TEMPLATE_DEMO_POLICY:-consul-template-demo-policy}

export LOG=${CONSUL_TEMPLATE_TOP}/consul-template-demo.log

function log() {
  echo "$(date) [$1] $2" | tee -a ${LOG}
}

echo "Creating CONSUL_TEMPLATE_TOP directory ${CONSUL_TEMPLATE_TOP} if it doesn't already exist."
mkdir -p ${CONSUL_TEMPLATE_TOP}
echo

touch ${LOG}
log INFO "Starting $0"
log INFO "Logging to ${LOG}"
log INFO "VAULT_ADDR is ${VAULT_ADDR}"
echo

log INFO "Creating policy ${CONSUL_TEMPLATE_DEMO_POLICY}"
vault policy write ${CONSUL_TEMPLATE_DEMO_POLICY} -<< EOF
path "${KV}/data/*" {
  capabilities = ["read"]
}

path "${KV}/metadata/*" {
  capabilities = ["read"]
}

path "auth/token/*" {
  capabilities = ["create", "update"]
}
EOF
echo

log INFO "Policy ${CONSUL_TEMPLATE_DEMO_POLICY} created as follows:"
vault policy read ${CONSUL_TEMPLATE_DEMO_POLICY}
echo

log INFO "Generating token with policy ${CONSUL_TEMPLATE_DEMO_POLICY}."
CONSUL_TEMPLATE_VAULT_TOKEN=$(vault token create -field=token -policy=${CONSUL_TEMPLATE_DEMO_POLICY} -ttl=5m)
echo

log INFO "Enabling kv-v2 secrets engine at ${KV}."
vault secrets enable -path=${KV} kv-v2
sleep 1
echo

log INFO "Writing some secrets at ${KV}."
for i in $(seq 1 3)
do
  vault kv put ${KV}/item-${i} token=$(uuidgen)
  echo "Secret at ${KV}/item-${i} is $(vault kv get -field=token ${KV}/item-${i})"
  echo
done
echo

log INFO "Generating consul-template config: ${CONSUL_TEMPLATE_CONFIG}"
cat << EOF > ${CONSUL_TEMPLATE_CONFIG}
vault {
  address     = "${VAULT_ADDR}"
  # namespace = "ns1"
  token       = "${CONSUL_TEMPLATE_VAULT_TOKEN}"
  # vault_agent_token_file = "${VAULT_AGENT_TOKEN_FILE}"
  renew_token = false
}

template {
  source      = "${SAMPLE_TEMPLATE}"
  destination = "${SAMPLE_RESULT}"
  perms       = 0640
}
EOF
echo

log INFO "Generating template for consul-template: ${SAMPLE_TEMPLATE}"
cat << EOF > ${SAMPLE_TEMPLATE}
item-1: {{ with secret "${KV}/item-1" }}{{ .Data.data.token }}{{ end }}

item-2: {{ with secret "${KV}/item-2" }}{{ .Data.data.token }}{{ end }}

item-3: {{ with secret "${KV}/item-3" }}{{ .Data.data.token }}{{ end }}
EOF
echo

log INFO "Running consul-template once. Template will be rendered to ${SAMPLE_RESULT}."
consul-template -once -config ${CONSUL_TEMPLATE_CONFIG}
echo

log INFO "Template rendered as follows:"
cat ${SAMPLE_RESULT}
echo

log INFO "Cleaning up"
log INFO "Disabling secrets engine mounted at ${KV}."
vault secrets disable ${KV}

log INFO "Revoking token ${CONSUL_TEMPLATE_VAULT_TOKEN}"
vault token revoke ${CONSUL_TEMPLATE_VAULT_TOKEN}

log INFO "Deleting policy ${CONSUL_TEMPLATE_DEMO_POLICY}"
vault policy delete ${CONSUL_TEMPLATE_DEMO_POLICY}
echo

log INFO "Done!"

exit 0
