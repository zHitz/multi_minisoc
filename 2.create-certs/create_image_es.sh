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
echo "                                  Images and Certificate Creation Script"
echo "                            Welcome to the Images and Certificate Creation Script"
echo "                             © 2023 HISSC CyberSoc. All rights reserved."
echo "--------------------------------------------------------------------------------------------------------"
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with equivalent privileges."
  exit 1
fi
# Check if the script has enough arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <elastic_version>"
  exit 1
fi
STACK_VERSION="$1"
source ../.env
# Create Container
echo "Step 0: Creating a Docker Container..."
if docker ps -a --format '{{.Names}}' | grep -q "es-create-certs"; then
    echo "Container 'es-create-certs' already exists, skipping creation."
else
    echo "Container 'es-create-certs' doesn't exist, creating..."
    docker run --name es-create-certs -d -it docker.elastic.co/elasticsearch/elasticsearch:"$STACK_VERSION"
fi
# Chain 0
# Ask the user if they already have a CA file
read -p "Do you have a CA file yet? (Y/N) [Y/y]: " answer

if [[ $answer == "Y" || $answer == "y" ]]; then
    # If yes, ask the user to enter the path to the CA file
    echo "Step 1: Copying the CA file to the Docker Container..."
    read -p "Please enter the path to the CA file: " ca_path_folder
    read -p "Please enter filename CA crt [ca.crt]: " ca_file_name_crt
    read -p "Please enter filename CA key [ca.key]: " ca_file_name_key
    read -p "Please enter the path to the instances.yml file [/root]: " ins_path_folder
    docker cp $ins_path_folder/instances.yml es-create-certs:/usr/share/elasticsearch/config/certs
    docker cp $ca_path_folder es-create-certs:/usr/share/elasticsearch/config/certs
    ca_folder_name=$(basename $ca_path_folder)
    echo "CA folder name: $ca_folder_name"
    echo "Step 2: Creating ES Server Certificates..."
    docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/$ca_folder_name/$ca_file_name_crt --ca-key config/certs/$ca_folder_name/$ca_file_name_key"
    docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "unzip config/certs/certs.zip -d config/certs"
    # Chain 4 Copy all files to the host
    docker cp es-create-certs:/usr/share/elasticsearch/config/certs .
    echo "Certificates created and copied to the host."
    echo "Step 3: Starting create image for Elasticsearch.........."
    read -p "Please enter image name [his-cybersoc/logs-example:8.5.0]: " image_name
    echo "Step 3.1: Starting commit image for Elasticsearch.........."
    docker commit es-create-certs $image_name
    docker images "$image_name"
    read -p "Please enter filename .tar [image-his-cybersoc-logs-example:8.5.0.tar]: " filename_tar
    echo "Step 3.2: Starting build image to file .tar for Elasticsearch.........."
    save_command="docker save -o ../5.deploy_elastic_single/images/$filename_tar $image_name"
    $save_command
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "File '$filename_tar' has been successfully created"
        echo "IMAGE_FILE_ES=$filename_tar" >> ../.env
        echo "IMAGE_NAME="$image_name"" >> ../.env
    else
        echo "File '$filename_tar' was not found. 'docker save' may have failed."
    fi
    docker rm -f es-create-certs
else
    # If no, create a new CA file
    read -p "Please enter the path to the instances.yml file [/root]: " ins_path_folder
    docker cp $ins_path_folder/instances.yml es-create-certs:/usr/share/elasticsearch/config/certs
    # Chain 1,2 Create and unzip CA folder
    echo "Step 1: Creating and Unzipping ES Server CA Folder..."
    docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip && unzip config/certs/ca.zip -d config/certs"
    # Chain 3 Create Certs
    echo "Step 2: Creating ES Server Certificates..."
    docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key"
    docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "unzip config/certs/certs.zip -d config/certs"
    # Chain 4 Copy all files to the host
    docker cp es-create-certs:/usr/share/elasticsearch/config/certs .
    echo "Certificates created and copied to the host."
    # Chain 5 Create image
    echo "Step 3: Starting create image for Elasticsearch.........."
    read -p "Please enter image name [his-cybersoc/logs-example:8.5.0]: " image_name
    read -p "Please enter filename .tar [image-his-cybersoc-logs-example:8.5.0.tar]: " filename_tar
    echo "Step 3.1: Starting commit image for Elasticsearch.........."
    docker commit es-create-certs $image_name
    docker images "$image_name"
    read -p "Please enter filename .tar [image-his-cybersoc-logs-example:8.5.0.tar]: " filename_tar
    echo "Step 3.2: Starting build image to file .tar for Elasticsearch.........."
    save_command="docker save -o ../5.deploy_elastic_single/images/$filename_tar $image_name"
    $save_command
    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "File '$filename_tar' has been successfully created"
    else
        echo "File '$filename_tar' was not found. 'docker save' may have failed."
    fi
    docker rm -f es-create-certs
fi