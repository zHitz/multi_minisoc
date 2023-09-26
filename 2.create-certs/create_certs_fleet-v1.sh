#!/bin/bash
clear 
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
# Create Container
echo "Step 0: Creating a Docker Container..."
if docker ps -a --format '{{.Names}}' | grep -q "es-create-certs"; then
    echo "Container 'es-create-certs' already exists, skipping creation."
else
    echo "Container 'es-create-certs' doesn't exist, creating..."
    docker run --name es-create-certs -d -it docker.elastic.co/elasticsearch/elasticsearch:8.5.0
fi
# Chain 0
# Ask the user if they already have a CA file
read -p "Do you have a CA file yet? (Y/N): " answer

if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
    # If yes, ask the user to enter the path to the CA file
    echo "Step 1: Copying the CA file to the Docker Container..."
    read -p "Please enter the path to the CA file: " ca_path_folder
    docker cp "$ca_path_folder" es-create-certs:/usr/share/elasticsearch
    ca_folder_name=$(basename "$ca_path_folder")
    echo "CA folder name: $ca_folder_name"
    file_list=$(docker exec -it $(docker ps -aq --filter name=es-create-certs) ls "/usr/share/elasticsearch/$ca_folder_name")
    echo "Files in the CA folder: $file_list"
    read -p "Please enter the hostname of Fleet Server: " hostname_fleet
    read -p "Please enter the IP of Fleet Server: " ip_fleet
    read -p "Please enter the output file name for Fleet Server certs - Ex [fleet-certs.zip]: " certs_file_name
    if [ "$(echo "$file_list" | wc -l)" -eq 2 ] && [ "$(echo "$file_list" | uniq | wc -l)" -eq 1 ]; then
        echo "$ca_folder_name/$ca_file_name"
        # Chain 3 Create Certs
        echo "Step 2: Creating Fleet Server Certificates..."
        docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c \
        "bin/elasticsearch-certutil cert \
        --name fleet-server \
        --ca-cert "/usr/share/elasticsearch/$ca_folder_name/$ca_folder_name.crt" \
        --ca-key "/usr/share/elasticsearch/$ca_folder_name/$ca_folder_name.key" \
        --dns $hostname_fleet \
        --ip $ip_fleet \
        --pem --out /usr/share/elasticsearch/$certs_file_name"
        docker cp es-create-certs:/usr/share/elasticsearch/$certs_file_name .
        echo "Certificates created and copied to the host."
    else
        ca_file_name_crt=""
        ca_file_name_key=""
        # Check the names of each file and assign to the corresponding variables
        for file in $file_list; do
            if [[ "$file" == *.crt ]]; then
                ca_file_name_crt="$file"
            elif [[ "$file" == *.key ]]; then
                ca_file_name_key="$file"
            fi
        done
        # Chain 3 Create Certs
        echo "Step 2: Creating Fleet Server Certificates..."
        docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c \
        "bin/elasticsearch-certutil cert \
        --name fleet-server \
        --ca-cert "/usr/share/elasticsearch/$ca_folder_name/$ca_file_name_crt" \
        --ca-key "/usr/share/elasticsearch/$ca_folder_name/$ca_file_name_key" \
        --dns $hostname_fleet \
        --ip $ip_fleet \
        --pem --out /usr/share/elasticsearch/$certs_file_name"
        # Chain 4 Copy all files to the host
        docker cp es-create-certs:/usr/share/elasticsearch/$certs_file_name .
        echo "Certificates created and copied to the host."
    fi

else
    # If no, create a new CA file
    read -p "Please enter the output file name for Fleet Server CA - Ex [fleet-ca.zip]: " ca_file_name
    # Chain 1,2 Create and unzip CA folder
    echo "Step 1: Creating and Unzipping Fleet Server CA Folder..."
    docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c "bin/elasticsearch-certutil ca --pem -out /usr/share/elasticsearch/$ca_file_name && unzip /usr/share/elasticsearch/$ca_file_name"
    read -p "Please enter the hostname of Fleet Server: " hostname_fleet
    read -p "Please enter the IP of Fleet Server: " ip_fleet
    read -p "Please enter the output file name for Fleet Server certs - Ex [fleet-certs.zip]: " certs_file_name
    # Chain 3 Create Certs
    echo "Step 2: Creating Fleet Server Certificates..."
    docker exec -it $(docker ps -aq --filter name=es-create-certs) bash -c \
    "bin/elasticsearch-certutil cert \
    --name fleet-server \
    --ca-cert "/usr/share/elasticsearch/ca/ca.crt" \
    --ca-key "/usr/share/elasticsearch/ca/ca.key" \
    --dns $hostname_fleet \
    --ip $ip_fleet \
    --pem --out /usr/share/elasticsearch/$certs_file_name"
    # Chain 4 Copy all files to the host
    docker cp es-create-certs:/usr/share/elasticsearch/$certs_file_name .
    docker cp es-create-certs:/usr/share/elasticsearch/ca/ca.crt .
    echo "Certificates created and copied to the host."
fi

docker rm -f es-create-certs