#!/bin/bash
cat << "EOF"

██╗  ██╗██╗███████╗███████╗ ██████╗     ██████╗██╗   ██╗██████╗ ███████╗██████╗ ███████╗ ██████╗  ██████╗
██║  ██║██║██╔════╝██╔════╝██╔════╝    ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔═══██╗██╔════╝
███████║██║███████╗███████╗██║         ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝███████╗██║   ██║██║     
██╔══██║██║╚════██║╚════██║██║         ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗╚════██║██║   ██║██║     
██║  ██║██║███████║███████║╚██████╗    ╚██████╗   ██║   ██████╔╝███████╗██║  ██║███████║╚██████╔╝╚██████╗
╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝     ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝
                                                                                                         
EOF
# Ensure you are running this script as root or with equivalent privileges to configure kernel parameters.
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with equivalent privileges."
  exit 1
fi
# Check if the script has enough arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <elastic_version>"
  exit 1
fi
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Installing package need"
echo "---------------------------------------------------------------------------------------------------------------------"
# Install package need
packages=("python3" "python3-pip" "python3-dotenv" "requests")

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

# Retrieve arguments from the command line
STACK_VERSION="$1"
#PROJECT_NAME="$2"
source .env

echo "STACK_VERSION=$STACK_VERSION" >> .env
echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Pull images"
echo "---------------------------------------------------------------------------------------------------------------------"
# Pull Elasticsearch and Kibana images from Docker Hub
#docker pull docker.elastic.co/elasticsearch/elasticsearch:"$STACK_VERSION"
docker load -i 5.deploy_elastic_single/images/$IMAGE_FILE_ES
docker load -i images/images-his-cybersoc-dashboard_8.5.0.tar

# Create Network
echo "Create network docker....."
docker network create siem_net -d overlay
echo "---------------------------------------------------------------------------------------------------------------------"
# Deploy the Elasticsearch and Kibana stack using Docker Compose
#docker compose -p "$PROJECT_NAME" up -d
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
container_id=$(docker ps --filter "status=running" --format '{{.ID}} {{.Ports}}' | grep '0.0.0.0:9200->' | awk '{print $1}')
cmd_cp="docker cp $container_id:/usr/share/elasticsearch/config his-cybersoc-logs-config"
cmd_chmod="chmod 777 -R his-cybersoc-logs-config"
echo "Please run command copy config for Elasticsearch: \"$cmd_cp\" and \"$cmd_chmod\""
echo "And update compose on Portainer mount config for Elasticsearch"