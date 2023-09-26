#!/bin/bash
cat << "EOF"

██╗  ██╗██╗███████╗███████╗ ██████╗     ██████╗██╗   ██╗██████╗ ███████╗██████╗ ███████╗ ██████╗  ██████╗
██║  ██║██║██╔════╝██╔════╝██╔════╝    ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔═══██╗██╔════╝
███████║██║███████╗███████╗██║         ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████╗██║   ██║██║     
██╔══██║██║╚════██║╚════██║██║         ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗╚════██║██║   ██║██║     
██║  ██║██║███████║███████║╚██████╗    ╚██████╗   ██║   ██████╔╝███████╗██║  ██║███████║╚██████╔╝╚██████╗
╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝     ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝
                                                                                                         
EOF
echo "--------------------------------------------------------------------------------------------------------"
echo "                                  Deploy MiniSOC Multi-Node Script"
echo "                            Welcome to the Deploy MiniSOC Multi-Node Script"
echo "                             © 2023 HISSC CyberSoc. All rights reserved."
echo "--------------------------------------------------------------------------------------------------------"
# Ensure you are running this script as root or with equivalent privileges to configure kernel parameters.
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with equivalent privileges."
  exit 1
fi
read -p "Which version do you want to create a certificate for Elastic ? " STACK_VERSION
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Installing package need"
echo "---------------------------------------------------------------------------------------------------------------------"
# Install package need
packages=("python3" "python3-pip" "python3-dotenv" "requests" "zip")

# Kiểm tra và cài đặt từng gói
for package in "${packages[@]}"
do
    if dpkg -l | grep -q $package; then
        echo "$package installed."
    else
        echo "$package package not installed, intstalling..."
        sudo apt-get install -y $package
        echo "$package installed successfully."
    fi
done
# apt install python3-pip
# pip3 install python-dotenv requests


echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Configure kernel parameters for Elasticsearch"
echo "---------------------------------------------------------------------------------------------------------------------"
# Configure kernel parameters for Elasticsearch
sysctl -w vm.max_map_count=262144

# Save the configuration to /etc/sysctl.conf to apply it automatically on startup
if grep -q "vm.max_map_count=262144" /etc/sysctl.conf; then
    echo "Configuration already exists in /etc/sysctl.conf, no need to add."
else
    # Add the configuration to sysctl.conf if it doesn't exist
    echo "Adding vm.max_map_count=262144 to /etc/sysctl.conf..."
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    echo "Configuration has been added to /etc/sysctl.conf."
fi
echo "---------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------"

source .env

if grep -q "STACK_VERSION=" .env; then
    echo "STACK_VERSION already exists in .env, no need to add."
else
    # Add the configuration to sysctl.conf if it doesn't exist
    echo "Adding STACK_VERSION= to .env..."
    echo "STACK_VERSION=$STACK_VERSION" >> .env
    echo "Configuration has been added to .env."
fi
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Pull images"
echo "---------------------------------------------------------------------------------------------------------------------"
# Pull Elasticsearch and Kibana images from Docker Hub
#docker pull docker.elastic.co/elasticsearch/elasticsearch:"$STACK_VERSION"
docker load -i images/$IMAGE_FILE_ES
docker load -i images/images-his-cybersoc-dashboard_8.5.0.tar

echo "Config Kibana ......"
echo "
server.name: his-cybersoc-dashboard
server.host: "0.0.0.0"
elasticsearch.hosts: [ "https://$NODE_NAME_MASTER1:9200" ] #### edit http


# xpack.security.enabled: true
elasticsearch.username: "kibana_system"
elasticsearch.password: "$KIBANA_PASSWORD"
elasticsearch.ssl.certificateAuthorities: "/usr/share/kibana/config/certs/ca/ca.crt"
elasticsearch.ssl.verificationMode: certificate

server.ssl.certificate: "/usr/share/kibana/config/certs/his-cybersoc-dashboard.crt"
server.ssl.key: "/usr/share/kibana/config/certs/his-cybersoc-dashboard.key"
server.ssl.enabled: true
xpack.encryptedSavedObjects.encryptionKey: "032fe5fa33bd4a8ec9320a1592265d24"

#xpack.fleet.registryProxyUrl: http://x.x.x.x:8132

xpack.security.audit.enabled: true
xpack.reporting.capture.browser.chromium.disableSandbox: true
telemetry.enabled: false

xpack.reporting.roles.enabled: false
xpack.security.encryptionKey: "032fe5fa33bd4a8ec9320a1592265d24"
xpack.reporting.kibanaServer.hostname: localhost

monitoring.ui.container.elasticsearch.enabled: true
monitoring.ui.container.logstash.enabled: true

xpack.security.session.idleTimeout: "24h"
xpack.security.session.lifespan: "3d"
#xpack.actions.customHostSettings:
#  - url: smtp://x.x.x.x
#    smtp:
#      ignoreTLS: true
" >> /his-cybersoc/config/his-cybersoc-dashboard1/kibana.yml

# Create Network
echo "Create network docker....."
docker network create -d overlay --opt encrypted --attachable his-cybersoc_net
echo "---------------------------------------------------------------------------------------------------------------------"
cat << "EOF"

██████╗  ██████╗ ██████╗ ████████╗ █████╗ ██╗███╗   ██╗███████╗██████╗ 
██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝██╔══██╗
██████╔╝██║   ██║██████╔╝   ██║   ███████║██║██╔██╗ ██║█████╗  ██████╔╝
██╔═══╝ ██║   ██║██╔══██╗   ██║   ██╔══██║██║██║╚██╗██║██╔══╝  ██╔══██╗
██║     ╚██████╔╝██║  ██║   ██║   ██║  ██║██║██║ ╚████║███████╗██║  ██║
╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
                                                                                                                                  
EOF
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Create Portainer Stack"
echo "---------------------------------------------------------------------------------------------------------------------"
python3 create_stackv1.py
# Check if the stack was deployed successfully
if [ $? -eq 0 ]; then
  echo "The Elasticsearch and Kibana stack has been deployed and is running."
else
  echo "Deployment of the Elasticsearch and Kibana stack failed. Please check the logs for more information."
fi
zip -r docker-multi-node-backup.zip ../docker-multi-node-v1