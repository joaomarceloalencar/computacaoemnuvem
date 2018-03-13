#!/usr/bin/python

import json
import requests
import os 
import time


# Create tokens and retrieve services 
def get_auth_token(url, username, userdomain, project, projectdomain, password):
   headers = {'Content-Type':'application/json'}
   fields = { 
      "auth": {
         "identity": {
            "methods": ["password"],
            "password": {
               "user": {
                  "name": username,
                  "domain": { "id": userdomain },
                  "password": password
               }
            }
         },
         "scope": {
            "project": {
               "name": project,
               "domain": { "id": projectdomain }
            }
         }
      }
   }
   r = requests.post(url, data = json.dumps(fields), headers = headers)
   auth_response = {}
   
   token_id = r.headers['X-Subject-Token']
   auth_response['token'] = token_id
   
   data = r.json()
   for service in data['token']['catalog']:
      serviceName = service['type']
      serviceEndpoints = service['endpoints']
      for endpoint in serviceEndpoints:
         if endpoint['interface'] == "public":
            url = endpoint['url']
            auth_response[serviceName] = endpoint['url'] 
   return auth_response 

# List Services
def list_servers(token, url):
   headers = { 'Content-Type': 'application/json', 'X-Auth-Token': token }
   r = requests.get(url, headers = headers)
   data = r.json()
   for server in data['servers']:
      print server['name']
      print server['id']
      print '\n'

# Create Instance
def create_server(token, url, name, image, flavor, key):
   headers = { 'Content-Type': 'application/json', 'X-Auth-Token': token }
   fields = {
      "server": {
         "name": name,
         "imageRef": image,
         "flavorRef": flavor,
         "key_name" : key
      } 
   }
   r = requests.post(url, data = json.dumps(fields), headers = headers)
   data = r.json()
   return data['server']['id']

# Instance Status
def server_status(token, url, serverid):
   headers = { 'Content-Type': 'application/json', 'X-Auth-Token': token }
   r = requests.get(url + "/" + serverid, headers = headers)
   data = r.json()
   return data['server']['status']
 
if __name__ == '__main__':
   # Reading variables set by computacaoemnuvem-openrc.sh
   username = os.environ['OS_USERNAME']
   password = os.environ['OS_PASSWORD']
   url = os.environ['OS_AUTH_URL'] + "/auth/tokens"
   project = os.environ['OS_PROJECT_NAME']
   projectdomain = os.environ['OS_PROJECT_DOMAIN_ID']
   userdomain = projectdomain
   
   print username
   print password
   print url
   print project
   print userdomain
   print projectdomain

   # The return type is a dict
   response = get_auth_token(url, username, userdomain, project, projectdomain, password)
   print "Authentication Response:"
   print "Token: " + response['token']
   print "Compute Endpoint: " + response['compute']
   token = response['token']
   compute_url = response['compute']
 
   # Running instances
   print "Running Servers:"
   list_servers(token, compute_url + "/servers")

   # Create Instance
   servername = "testeAPI"
   
   # openstack image list
   image = "bad71d40-69f2-4a72-a005-8d6a26d44719" 

   # openstack flavor list
   flavor = "24c8a95a-379e-45d3-a700-a574eda3de0b"

   key = "alunoufc"
   serverid = create_server(token, compute_url + "/servers", servername, image, flavor, key)
   print "Server Created with ID: " + serverid 

   # Wait while the server is created
   status = server_status(token, compute_url + "/servers", serverid) 
   while status != "ACTIVE" : 
      time.sleep(2)
      print status
      status = server_status(token, compute_url + "/servers", serverid) 

