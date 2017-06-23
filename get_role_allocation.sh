
#!/bin/bash

export DCOS_URL=fernando-elasticl-xbxo8xrh2ih7-132663066.us-west-2.elb.amazonaws.com/
export USERNAME=bootstrapuser
export PASSWORD=deleteme


TOKEN=$(curl \
-H "Content-Type:application/json" \
--data '{ "uid":"'"$USERNAME"'", "password":"'"$PASSWORD"'" }' \
-X POST	\
http://$DCOS_URL/acs/api/v1/auth/login \
| jq -r '.token')


#SYSTEM HEALTH
API_ENDPOINT="/mesos/roles"

MESOS_ROLES=$(curl \
-H "Content-Type:application/json" \
-H "Authorization: token=$TOKEN" \
-X GET \
http://$DCOS_URL$API_ENDPOINT)

echo "MESOS_ROLES: "
echo "==============="
echo $MESOS_ROLES | jq -r .
