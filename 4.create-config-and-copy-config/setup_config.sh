#!/bin/bash

source_dir="."
config_dir="/his-cybersoc/config"

if [ ! -d "$config_dir" ]; then
fi

if [ -f "$source_dir/node_info.txt" ]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
      data="${BASH_REMATCH[1]}"

      data=$(echo "$data" | sed 's/node\.roles:.*//g' | tr -d '[:space:]')
      
      if [ ! -z "$data" ]; then
        cp "$source_dir/template.yml" "$config_dir/$data/"

        sed -i "s/{default_template}/$data/g" "$config_dir/$data/template.yml"
      fi
    fi

    if [[ "$line" == "node.roles:"* ]]; then
      roles="${line#node.roles: }"
      if [ ! -z "$roles" ]; then
        echo $roles
        echo $data
        sed -i "s/node.roles: {roles_template}/node.roles: $roles/g" "$config_dir/$data/template.yml"
      fi
    fi
  done < "$source_dir/node_info.txt"
else
  echo "node_info.txt not existed."
fi
