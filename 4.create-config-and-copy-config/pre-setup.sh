#!/bin/bash

yaml_file="2.create-certs/instances.yml"

base_directory="/"

node_info_file="./node_info.txt"


mkdir -p "${base_directory}his-cybersoc"

echo > "$node_info_file"
while IFS= read -r line; do
    if [[ "$line" == *"name:"* ]]; then
        name=$(echo "$line" | awk -F '"' '{print $2}')
        mkdir -p "${base_directory}his-cybersoc/data/$name"
        mkdir -p "${base_directory}his-cybersoc/config/$name"

        echo "[$name]" >> "$node_info_file"

        case "$name" in
            *master*)
                echo "node.roles: [ master ]" >> "$node_info_file"
                ;;
            *hot*)
                echo "node.roles: [ data_hot, data_content ]" >> "$node_info_file"
                ;;
            *warm*)
                echo "node.roles: [ data_warm, data_content ]" >> "$node_info_file"
                ;;
            *cold*)
                echo "node.roles: [ data_cold, data_content ]" >> "$node_info_file"
                ;;
            *coordination*)
                echo "node.roles: [ remote_cluster_client ]" >> "$node_info_file"
                ;;
            *ml*)
                echo "node.roles: [ ml ]" >> "$node_info_file"
                ;;
            *ingest*)
                echo "node.roles: [ ingest, transform ]" >> "$node_info_file"
                ;;
            *)

                echo "node.roles: [ unknown ]" >> "$node_info_file"
                ;;
        esac
        echo "" >> "$node_info_file"
    fi
done < "$yaml_file"
echo "Folders created successfully."
