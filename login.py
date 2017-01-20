#!/usr/bin/env python3
#
# get_token.py: retrieve and export the DC/OS token based on username and password on CLI
#
# Author: Fernando Sanchez [ fernando at mesosphere.com ]
#
#reference:
#http://mesos.apache.org/documentation/latest/endpoints/master/slaves/

#prereqs on redhat7
# rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# yum install -y epel-release
# yum install -y git python-pip python34 jq nginx
# curl https://bootstrap.pypa.io/get-pip.py | python3.4
# pip3 install --upgrade pip jsonschema requests

#
import os
import requests
import json
import argparse

def login_to_cluster ( DCOS_IP, username, password ):
	"""
	Log into the cluster whose DCOS_IP is specified in 'config' in order to get a valid token, using the username and password in 'config'. 
	Return the token obtained or False if error.
	"""
	api_endpoint = '/acs/api/v1/auth/login'
	url = 'http://'+DCOS_IP+api_endpoint
	headers = {
		'Content-type': 'application/json'
	}
	data = { 
		"uid":		username,
		"password":	password
		}

	try:
		request = requests.post(
			url,
			data = json.dumps( data ),
			headers=headers
			)
		request.raise_for_status()
		print('**INFO: Login to cluster {0} as {1} OK: {2}'.format( DCOS_IP, username, request.status_code ) )
	except ( requests.exceptions.HTTPError, requests.exceptions.ConnectionError ) as error:
		print('**ERROR: Login to cluster {0} as {1} ERROR: {2}'.format( DCOS_IP, username, request.text) )
		return False

	#return the token
	return request.json()['token']

if __name__ == "__main__":

	#parse command line arguments
	parser = argparse.ArgumentParser(description='Login into a DC/OS cluster and get the token. Export it as DCOS_IP', \
		usage='login.py -s [SERVER] -u [USERNAME] -p [PASSWORD]'
		)
	parser.add_argument('-s', '--server', help='server to log into', required=True)
	parser.add_argument('-u', '--username', help='username to login with', required=True)
	parser.add_argument('-p', '--password', help='password to login with', required=True)
	args = vars(parser.parse_args())
	token = login_to_cluster(
		args['server'],
		args['username'],
		args['password']
		)
	os.environ['DCOS_IP']=token
	print('**INFO: DC/OS token obtained from {0}: \n{1}'.format( DCOS_IP, token ) )
	sys.exit(0)