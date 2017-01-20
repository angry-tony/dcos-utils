#!/usr/bin/env python3
#
# get_nodes.py: retrieve and save the node state from a DC/OS cluster
#
# Author: Fernando Sanchez [ fernando at mesosphere.com ]
#
# Get the node state from a DC/OS cluster. Provide a list of
# the Total, Active and Inactive nodes, along with their roles.

# Parameters as environment variables:
#
# DCOS_IP : IP address or name of cluster to be checked
# DCOS_TOKEN : DCOS_TOKEN to be used for authentication

#reference:
#http://mesos.apache.org/documentation/latest/endpoints/master/slaves/

#prereqs on redhat7
# rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# yum install -y epel-release
# yum install -y git python-pip python34 jq nginx
# curl https://bootstrap.pypa.io/get-pip.py | python3.4
# pip3 install --upgrade pip jsonschema requests

import sys
import os
import requests
import json
from socket import error as socket_error

SEPARATOR="="*42

#Load configuration from environment variables
DCOS_IP=os.environ['DCOS_IP']
DCOS_TOKEN=os.environ['DCOS_TOKEN']


print('**DEBUG: DCOS_IP: {}'.format(DCOS_IP))
print('**DEBUG: DCOS_TOKEN: {}'.format(DCOS_TOKEN))
if DCOS_IP=='' or TOKEN=='':
	print('** ERROR: required variables DCOS_IP: {0}, TOKEN: {1}, \
		not set appropriately. Please set and re-run'.format(DCOS_IP,DCOS_TOKEN))

#Get list of nodeS with their state from DC/OS. 
#This will be later used as index to get all user-to-group memberships
api_endpoint = '/system/health/v1/nodes'
url = 'http://'+DCOS_IP+api_endpoint
headers = {
	'Content-type': 'application/json',
	'Authorization': 'DCOS_TOKEN='+DCOS_TOKEN,
}
try:
	request = requests.get(
		url,
		headers=headers,
		)
	#show progress after request
	print( '** INFO: GET Nodes: {0} \n'.format( request.status_code ) )
except (
	requests.exceptions.ConnectionError ,\
	socket_error,\
	requests.packages.urllib3.exceptions.NewConnectionError ,\
	requests.packages.urllib3.exceptions.MaxRetryErrorrequests.exceptions.HTTPError,\
	ConnectionRefusedError
	) as error:
	print ('** ERROR: GET Nodes: {} \n'.format( error ) ) 

#2xx HTTP status code is success
if str(request.status_code)[0] == '2':

	#parseable output
	print("\n\n**OUTPUT:{'nodes':{}}".format(request.text))
	#Create a list of nodes
	nodes_dict = json.loads( request.text )
	nodes_list = nodes_dict['nodes']
	print( "TOTAL nodes: 				{0}".format( len( nodes_list ) ) )
	print(SEPARATOR)
	healthy_nodes = [ node for node in nodes_list if not node['health'] ]  #health==0 means healthy
	print( "HEALTHY nodes: 			{0}".format( len( healthy_nodes ) ) )
	print(SEPARATOR)
	for index, node in ( enumerate( healthy_nodes ) ):
		print ( "Node #{0}: {1:24} - {2}".format( index, node['host_ip'], node['role']) )
	unhealthy_nodes = [ node for node in nodes_list if node['health'] ]   #health!=0 means unhealthy
	print(SEPARATOR)
	print("UNHEALTHY nodes: 			{0}".format( len( unhealthy_nodes ) ) )
	print(SEPARATOR)
	for index, node in ( enumerate( unhealthy_nodes ) ):
		print ( "Node #{0}: {1:24} - {2}".format( index, node['host_ip'], node['role']) )


else:
	print ('** ERROR: GET Node: {} \n'.format( request.text ) ) 	

print( '\n** INFO: GET Node: 							Done. \n' )





