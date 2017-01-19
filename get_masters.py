#!/usr/bin/env python3
#
# get_masters.py: retrieve and save the master state from a DC/OS cluster
#
# Author: Fernando Sanchez [ fernando at mesosphere.com ]
#
# Get the masters state from a DC/OS cluster. Provide a list of
# the Total, Active and Inactive agents.
# Parameters as environment variables:
#
# DCOS_IP : IP address or name of cluster to be checked
# TOKEN : Token to be used for authentication

# This takes EXACTLY two arguments:
# - First argument is the server to check
# - Second argument is the expected number of masters

#reference:
#http://mesos.apache.org/documentation/latest/endpoints/master/slaves/

import sys
import os
import requests
import json
import argparse

#Parse command line arguments
parser = argparse.ArgumentParser(description='Retrieve and check the state of a DC/OS cluster', \
	usage='get_masters.py -s [SERVER] -n [EXPECTED_NUMBER_OF_MASTERS]'
	)
parser.add_argument('-s', '--server', help='server to check', required=True)
parser.add_argument('-n', '--masters', help='expected number of masters in the cluster', required=True)
args = vars(parser.parse_args())
print('**DEBUG: server is: {0}'.format( args['server'] ))
print('**DEBUG: num_master is: {0}'.format( args['masters'] ))


#Load configuration from environment variables
DCOS_IP=args['server']
masters=int(args['masters'] )
TOKEN=os.environ['TOKEN']
#TODO check they exist and have the right format

#CHECK #1
#check from zookeeper the number of servers and leaders matches what is expected.
EXHIBITOR_STATUS_URL = 'http://'+DCOS_IP+':8181/exhibitor/v1/cluster/status'
print('**INFO: Expected cluster size: {}'.format( masters ))
#get the actual cluster size from zookeeper
try:
	response = requests.get(EXHIBITOR_STATUS_URL)
except requests.exceptions.ConnectionError as ex:
	print('**ERROR: Could not connect to exhibitor: {}'.format(ex))
	sys.exit(1)
if str(response.status_code)[0] != '2':
	print('**ERROR: Could not get exhibitor status: {}, Status code: {}'.format(EXHIBITOR_STATUS_URL, response.status_code))
	sys.exit(1)
data = response.json()
#count the number of serving nodes and leaders
serving = 0
leaders = 0
for node in data:
	if node['isLeader']:
		leaders += 1
	if node['description'] == 'serving':
		serving += 1

if serving != masters or leaders != 1:
		print('**ERROR: Expected {0} servers and 1 leader, got {1} servers and {2} leaders. Exiting.'.format(masters, serving, leaders))
		sys.exit(1)
else:
		print('**INFO: server/leader check OK: {0} servers and {1} leader.'.format(serving, leaders))

#CHECK #2
#https://docs.mesosphere.com/1.8/administration/installing/cloud/aws/upgrading/
#METRICS: "registrar" has the metric/registrar/log recovered with a value of 1
#http://<dcos_master_private_ip>:5050/metrics/snapshot
api_endpoint=':5050/metrics/snapshot'
url = 'http://'+DCOS_IP+api_endpoint
headers = {
	'Content-type': 'application/json',
	'Authorization': 'token='+TOKEN,
}
try:
	request = requests.get(
		url,
		headers=headers,
		)
	#show progress after request
	sys.stdout.write( '** INFO: GET Metrics: {0} \n'.format( request.status_code ) )
	sys.stdout.flush()
except requests.exceptions.HTTPError as error:
	print ('** ERROR: GET Metrics: {} \n'.format( requests.text ) )

print('**DEBUG: Metrics is'.format(request.text))
#TODO: print relevant metrics and make sure that /registrar/log

#CHECK #3
#Get general health of the system and make sure EVERYTHING is Healthy
api_endpoint = '/system/health/v1/report'
url = 'http://'+DCOS_IP+api_endpoint
headers = {
	'Content-type': 'application/json',
	'Authorization': 'token='+TOKEN,
}
try:
	request = requests.get(
		url,
		headers=headers,
		)
	#show progress after request
	sys.stdout.write( '** INFO: GET Health Report: {0} \n'.format( request.status_code ) )
	sys.stdout.flush()
except requests.exceptions.HTTPError as error:
	print ('** ERROR: GET Health Report: {} \n'.format( requests.text ) ) 

#2xx HTTP status code is success
if str(request.status_code)[0] == '2':
	
	response = json.loads( request.text ) 
	#print relevant parameters from healthx
	print('**DEBUG: response is: '.format(response))	
	for index,unit in enumerate( response['Units'] ):
		print('Unit#: {0}		Name: {1}			State: {2}'.format( index, unit['UnitName'], unit['Health'] ) )
		if unit['Health']: #not 0 means unhealthy, print all children
			for node in unit['Nodes']:
				print('Unit#: {0}		Name: {1}			IP: {2}		State: {2}'.format( index, unit['UnitName'], node['IP'], node['Health'] ) )
else:
	print ('** ERROR: GET Health: {} \n'.format( error ) ) 	

sys.stdout.write( '\n** INFO: GET System Health: 							Done. \n' )





