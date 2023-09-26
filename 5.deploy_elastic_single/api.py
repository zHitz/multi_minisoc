# %%
# %%
import os
import json
import requests
import getpass
from dotenv import load_dotenv
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# %%
# Portainer API base URL

# input_ip = input("Input IP Portainer: ")

base_url = f'https://192.168.1.4:9443/api'

# Authentication endpoint
auth_endpoint = '/auth'

# Replace with your Portainer username and password
username = 'admin'
password = 'aeeXq5yfLHKO0Cw'

# Create a session
session = requests.Session()

# Prepare authentication payload
auth_payload = {
    "Username": username,
    "Password": password
}

# Replace with the name of your stack
# stack_name = input("Input Stack Name: ")

# %%
# Make the POST request to authenticate
response = session.post(f"{base_url}{auth_endpoint}", json=auth_payload,verify=False)

# Check the response status code
if response.status_code == 200:
    print("Authentication successful")

    # Parse the JSON response
    auth_data = response.json()

    # Access and print individual values
    auth_token = auth_data.get("jwt", "")
    
    print(f"Access Token: {auth_token}")

    # You can now use the session for authenticated requests
else:
    print(f"Authentication failed with status code: {response.status_code}")
    print(response.json())  # Print the response content for debugging

# %%
# Endpoint for listing all endpoints
endpoint_list_endpoint = '/endpoints'

# Create a session with the authorization header
headers = {
    'Authorization': f'Bearer {auth_token}',
}

# %%
# Make the GET request to list endpoints
response = requests.get(f"{base_url}{endpoint_list_endpoint}", headers=headers, verify=False)

# Check the response status code
if response.status_code == 200:
    print("Endpoints listed successfully")
    
    # Parse the JSON response
    endpoints_data = response.json()

    # Access and work with the endpoint data as needed
    # print(response.json())
    for endpoint in endpoints_data:
        print(f"Endpoint ID: {endpoint['Id']}")
        print(f"Endpoint Name: {endpoint['Name']}")
        if endpoint['Name'] == "primary":
            local_enviroment_id = f"{endpoint['Id']}"
            print(local_enviroment_id)
        # Add more attributes as needed
else:
    print(f"Failed to list endpoints with status code: {response.status_code}")
    print(response.json())  # Print the response content for debugging

# %%
# Endpoint for listing all endpoints
endpoint_list_endpoint = f'/endpoints/1/docker/info'

# Create a session with the authorization header
headers = {
    'Authorization': f'Bearer {auth_token}',
}

# %%
# Make the GET request to list endpoints
response = requests.get(f"{base_url}{endpoint_list_endpoint}", headers=headers, verify=False)

# Check the response status code


if response.status_code == 200:
    swarm_data = response.json()
    # for endpoint in swarm_data:
    #     # print(f"Endpoint ID: {endpoint['Id']}")
    #     # print(f"Endpoint Name: {endpoint['Swarm']}")
    # print("Endpoints listed successfully")
    # Parse the JSON response
    swarm_data = response.json()
    # Trích xuất cluster ID
    cluster_id = swarm_data['Swarm']['Cluster']['ID']

    # In cluster ID
    print(cluster_id)
        
else:
    print(f"Failed to list endpoints with status code: {response.status_code}")
    print(response.json())  # Print the response content for debugging


