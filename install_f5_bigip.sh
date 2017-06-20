#!/bin/bash

# install_f5_bigip.sh: Install F5's BigIP LoadBalancer on a running Enterprise DC/OS cluster
# automates creating a service account and credentials.

#Parameters
export F5_BIGIP_SVC_ACT_NAME=dcos_f5_bigip
export TMP_DIR="./tmp_dcos"
export F5_BIGIP_PRV_KEY=${TMP_DIR}"/"dcos_f5_bigip-private-key.pem
export F5_BIGIP_PUB_KEY=${TMP_DIR}"/"dcos_f5_bigip-public-key.pem
export DCOS_CA_CERT_FILE=${TMP_DIR}"/"dcos_ca.crt
export DCOS_AUTH_TOKEN=${TMP_DIR}"/"dcos_token
export F5_BIGIP_OPTIONS_FILE=${TMP_DIR}"/"dcos_f5_bigip_options.json
export F5_BIGIP_SECRET_NAME=dcos_f5_bigip_secret
export F5_BIGIP_JSON_FILE=f5_bigip.json
export ESCAPE_KEY="./escape_key.py"

export AUTH_ENDPOINT="/acs/api/v1/auth/login"

#test if python is present
command -v python >/dev/null 2>&1 || { echo "This script requires Python but it's not installed. Please install Python and re-run. Aborting." >&2; exit 1; }

#get DC/OS cluster address
read -p "Enter DC/OS cluster address: " DCOS_IP
read -p "Enter DC/OS username: " USERNAME
read -p "Enter DC/OS password: " PASSWORD
export DCOS_URL="http://"$DCOS_IP"/"

#test login, get a token
TOKEN=$(curl \
-skSL \
-H "Content-Type:application/json" \
--data '{ "uid":"'"$USERNAME"'", "password":"'"$PASSWORD"'" }' \
-X POST \
$DCOS_URL$AUTH_ENDPOINT \
| jq -r ".token")

#check whether login was successful, exit otherwise
if [ -z "$TOKEN" ]; then
	echo "** ERROR: Login failed. Please double-check login parameters. Exiting..."
	exit
else
	echo "** INFO: Login to DC/OS at "$DCOS_IP" successful."
fi

#create working dir
echo "** INFO: Refreshing temp directory..."
rm -rf ${TMP_DIR}
mkdir -p ${TMP_DIR}

#export DC/OS configuration
echo "** INFO: Logging into DC/OS..."
dcos config set core.dcos_url $DCOS_URL
#login to dcos
dcos auth login --username=$USERNAME --password=$PASSWORD

#install Enterprise CLI
echo "** INFO: Installing DC/OS Enterprise CLI..."
dcos package install --yes --cli dcos-enterprise-cli

#retrieve DCOS certificate
echo "** INFO: Retrieving DC/OS remote CA cert..."
curl -skSL ${DCOS_URL}/ca/dcos-ca.crt -o ${DCOS_CA_CERT_FILE}

#create F5 BIG IP service account
echo "** INFO: Creating a keypair for F5 on DC/OS..."
dcos security org service-accounts keypair -l 4096 ${F5_BIGIP_PRV_KEY} ${F5_BIGIP_PUB_KEY}

#escape the public key (swap newlines for /n) to use in credentials
#not needed for "service account create" command
echo "** INFO: Formatting keys..."
export F5_BIGIP_PUB_KEY_ESCAPED=`${ESCAPE_KEY} ${F5_BIGIP_PUB_KEY}`
export F5_BIGIP_PRV_KEY_ESCAPED=`${ESCAPE_KEY} ${F5_BIGIP_PRV_KEY}`
export DCOS_CA_CERT_ESCAPED=`${ESCAPE_KEY} ${DCOS_CA_CERT_FILE}`

#create a service account for F5
echo "** INFO: Creating a service account for F5 on DC/OS..."
dcos security org service-accounts create -p $F5_BIGIP_PUB_KEY -d $F5_BIGIP_SVC_ACT_NAME" service account" $F5_BIGIP_SVC_ACT_NAME
echo "** INFO: Created a service account for F5 on DC/OS:"
dcos security org service-accounts show $F5_BIGIP_SVC_ACT_NAME

#sleep for all API calls to be done
sleep 3

#Provide F5 permissions to access Marathon event bus
echo "** INFO: Authorizing the service account for F5 on DC/OS..."
curl -skSL -X PUT -H 'Content-Type: application/json' -d '{"description": "Marathon Services"}' -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F
curl -skSL -X PUT -H 'Content-Type: application/json' -d '{"description": "Marathon Events"}' -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events
curl -skSL -X PUT -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/$F5_BIGIP_SVC_ACT_NAME/read
curl -skSL -X PUT -H "Authorization: token=$(dcos config show core.dcos_acs_token)" $(dcos config show core.dcos_url)/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events/users/$F5_BIGIP_SVC_ACT_NAME/read

sleep 3

#Create secret for service account
echo "** INFO: Creating secret for F5 on DC/OS..."
dcos security secrets create-sa-secret $F5_BIGIP_PRV_KEY $F5_BIGIP_SVC_ACT_NAME $F5_BIGIP_SECRET_NAME
dcos security secrets list /
echo "** INFO: Created secret for F5 on DC/OS:"
dcos security secrets get /$F5_BIGIP_SECRET_NAME --json | jq -r .value | jq

sleep 3

#create credentials using the escaped private key
export DCOS_AUTH_CREDENTIALS="{ \"scheme\": \"RS256\", \"uid\": \"${F5_BIGIP_SVC_ACT_NAME}\", \"login_endpoint\": \"https://leader.mesos/acs/api/v1/auth/login\", \"private_key\": \"${F5_BIGIP_PRV_KEY_ESCAPED}\" }"

# Launch Marathon-LB using the secret and the cert created above
cat > $F5_BIGIP_JSON_FILE << EOF
{
  "id": "marathon-bigip-ctlr",
  "cpus": 0.5,
  "mem": 64.0,
  "instances": 1,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "f5networks/marathon-bigip-ctlr:1.0.0",
      "network": "BRIDGE"
    }
  },
  "env": {
    "MARATHON_URL": "http://marathon.mesos:8080",
    "F5_CC_PARTITIONS": "mesos",
    "F5_CC_BIGIP_HOSTNAME": "10.190.25.80",
    "F5_CC_BIGIP_USERNAME": "admin",
    "F5_CC_BIGIP_PASSWORD": "admin",
    "F5_CC_DCOS_AUTH_CREDENTIALS": "{ \"scheme\": \"RS256\", \"uid\": \"${F5_BIGIP_SVC_ACT_NAME}\", \"login_endpoint\": \"https://leader.mesos/acs/api/v1/auth/login\", \"private_key\": \"${F5_BIGIP_PRV_KEY_ESCAPED}\" }",
    "F5_CC_MARATHON_CA_CERT": "${DCOS_CA_CERT_ESCAPED}"
  }
}
EOF

dcos marathon app add $F5_BIGIP_JSON_FILE
