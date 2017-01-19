DCOS_URL=fernando-elasticl-1plu4pyehvk68-1475846986.us-east-1.elb.amazonaws.com
USERNAME=bootstrapuser
PASSWORD=deleteme

SYSTEM_HEALTH_FILE="./system_health.json"
SYSTEM_HEALTH_UNITS_FILE="./system_health_units.json"
SYSTEM_HEALTH_NODES_FILE="./system_health_nodes.json"
SYSTEM_HEALTH_REPORT_FILE="./system_health_report.json"

TOKEN=$(curl \
-H "Content-Type:application/json" \
--data '{ "uid":"'"$USERNAME"'", "password":"'"$PASSWORD"'" }' \
-X POST	\
http://$DCOS_URL/acs/api/v1/auth/login \
| jq -r '.token')


#SYSTEM HEALTH
API_ENDPOINT="/system/health/v1"

echo "Contacting: http://"$DCOS_URL$API_ENDPOINT
SYSTEM_HEALTH=$(curl \
-H "Content-Type:application/json" \
-H "Authorization: token=$TOKEN" \
-X GET \
http://$DCOS_URL$API_ENDPOINT)

echo "SYSTEM HEALTH: "
echo "==============="
echo $SYSTEM_HEALTH | jq
echo $SYSTEM_HEALTH > $SYSTEM_HEALTH_FILE


#/system/health/v1/units
API_ENDPOINT="/system/health/v1/units"

echo "Contacting: http://"$DCOS_URL$API_ENDPOINT
SYSTEM_HEALTH_UNITS=$(curl \
-H "Content-Type:application/json" \
-H "Authorization: token=$TOKEN" \
-X GET \
http://$DCOS_URL$API_ENDPOINT)

echo "SYSTEM HEALTH UNITS: "
echo "====================="
echo $SYSTEM_HEALTH_UNITS | jq
echo $SYSTEM_HEALTH_UNITS > $SYSTEM_HEALTH_UNITS_FILE


#/system/health/v1/nodes
API_ENDPOINT="/system/health/v1/nodes"

echo "Contacting: http://"$DCOS_URL$API_ENDPOINT
SYSTEM_HEALTH_NODES=$(curl \
-H "Content-Type:application/json" \
-H "Authorization: token=$TOKEN" \
-X GET \
http://$DCOS_URL$API_ENDPOINT)

echo "SYSTEM HEALTH NODES: "
echo "====================="
echo $SYSTEM_HEALTH_NODES | jq
echo $SYSTEM_HEALTH_NODES > $SYSTEM_HEALTH_NODES_FILE


#/system/health/v1/report
API_ENDPOINT="/system/health/v1/report"

echo "Contacting: http://"$DCOS_URL$API_ENDPOINT
SYSTEM_HEALTH_REPORT=$(curl \
-H "Content-Type:application/json" \
-H "Authorization: token=$TOKEN" \
-X GET \
http://$DCOS_URL$API_ENDPOINT)

echo "SYSTEM HEALTH REPORT: "
echo "====================="
echo $SYSTEM_HEALTH_REPORT | jq
echo $SYSTEM_HEALTH_REPORT > $SYSTEM_HEALTH_REPORT_FILE

