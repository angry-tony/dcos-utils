#!/usr/bin/env python3
#
# get_agents.py: retrieve and save the agent state from a DC/OS cluster
#
# Author: Fernando Sanchez [ fernando at mesosphere.com ]
#
# Get the agent state from a DC/OS cluster. Provide a list of
# the Total, Active and Inactive agents.

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

#Load configuration from environment variables
DCOS_IP=os.environ['DCOS_IP']
TOKEN=os.environ['TOKEN']

#Get list of AGENTS with their state from DC/OS. 
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
	sys.stdout.write( '** INFO: GET Agents: {0} \n'.format( request.status_code ) )
	sys.stdout.flush()
except requests.exceptions.HTTPError as error:
	print ('** ERROR: GET Agents: {} \n'.format( error ) ) 

#2xx HTTP status code is success
if str(request.status_code)[0] == '2':
	
	#Create a list of agents
	agents_dict = json.loads( request.text )
	agents_list = agents_dict['nodes']

	print( "TOTAL agents: 				{0}".format( len( agents_list ) ) )
	print("="*42)
	healthy_agents = [ agent for agent in agents_list if not agent['health'] ]  #health==0 means healthy
	print( "HEALTHY agents: 			{0}".format( len( healthy_agents ) ) )
	print("="*42)
	for index, agent in ( enumerate( healthy_agents ) ):
		print ( "Agent #{0}: {1} - {2}".format( index, agent['host_ip'], agent['role']) )
	unhealthy_agents = [ agent for agent in agents_list if agent['health'] ]   #health!=0 means unhealthy
	print("="*42)
	print("UNHEALTHY agents: 			{0}".format( len( unhealthy_agents ) ) )
	print("="*42)
	for index, agent in ( enumerate( unhealthy_agents ) ):
		print ( "Agent #{0}: {1} - {2}".format( index, agent['host_ip'], agent['role']) )
	input("Press ENTER to continue...")

else:
	print ('** ERROR: GET Agents: {} \n'.format( error ) ) 	

sys.stdout.write( '\n** INFO: GET Agents: 							Done. \n' )





