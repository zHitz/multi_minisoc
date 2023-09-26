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
echo "                                  Certificate Creation Script"
echo "                            Welcome to the Certificate Creation Script"
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
    read -p "Please enter the path to the instances.yml file [/root]: " ins_path_folder
    docker cp $ins_path_folder/instances.yml es-create-certs:/usr/share/elasticsearch/config/certs
    docker cp $ca_path_folder es-create-certs:/usr/share/elasticsearch/config/certs
    ca_folder_name=$(basename $ca_path_folder)
    echo "CA folder name: $ca_folder_name"
    file_list=$(ls $ca_path_folder)
    echo "Files in the CA folder: $file_list"
    if [[ $(echo "$file_list" | wc -l) -eq 2 && $(echo "$file_list" | uniq | wc -l) -eq 1 ]]; then
        # Chain 3 Create Certs
        echo "Step 2: Creating ES Server Certificates..."
        docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/$ca_folder_name/$ca_folder_name.crt --ca-key config/certs/$ca_folder_name/$ca_folder_name.key"
        docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "unzip config/certs/certs.zip -d config/certs"
        docker cp es-create-certs:/usr/share/elasticsearch/config/certs .
        echo "Certificates created and copied to the host."
    else
        ca_file_name_crt=""
        ca_file_name_key=""
        # Check the names of each file and assign to the corresponding variables
        for file in $file_list; do
            if [[ $file == *.crt ]]; then
                ca_file_name_crt="$file"
            elif [[ $file == *.key ]]; then
                ca_file_name_key="$file"
            fi
        done
        # Chain 3 Create Certs
        echo "Step 2: Creating ES Server Certificates..."
        docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/$ca_folder_name/$ca_file_name_crt --ca-key config/certs/$ca_folder_name/$ca_file_name_key"
        docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "unzip config/certs/certs.zip -d config/certs"
        # Chain 4 Copy all files to the host
        docker cp es-create-certs:/usr/share/elasticsearch/config/certs .
    fi

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
fi

docker rm -f es-create-certs