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
# TOKEN : Token to be used for authentication

#reference:
#http://mesos.apache.org/documentation/latest/endpoints/master/slaves/

import sys
import os
import requests
import json

SEPARATOR="="*42

#Load configuration from environment variables
DCOS_IP=os.environ['DCOS_IP']
TOKEN=os.environ['TOKEN']

#Get list of nodeS with their state from DC/OS. 
#This will be later used as index to get all user-to-group memberships
api_endpoint = '/system/health/v1/nodes'
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
	sys.stdout.write( '** INFO: GET Nodes: {0} \n'.format( request.status_code ) )
	sys.stdout.flush()
except requests.exceptions.HTTPError as error:
	print ('** ERROR: GET Nodes: {} \n'.format( error ) ) 

#2xx HTTP status code is success
if str(request.status_code)[0] == '2':
	
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
	input("Press ENTER to continue...")

else:
	print ('** ERROR: GET Node: {} \n'.format( error ) ) 	

sys.stdout.write( '\n** INFO: GET Node: 							Done. \n' )




