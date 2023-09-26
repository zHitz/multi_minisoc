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
echo "                                  Setup Images Script"
echo "                            Welcome to the Setup Images Script"
echo "                             © 2023 HISSC CyberSoc. All rights reserved."
echo "--------------------------------------------------------------------------------------------------------"
# Ensure you are running this script as root or with equivalent privileges to configure kernel parameters.
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with equivalent privileges."
  exit 1
fi

echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Start Playbook"
echo "---------------------------------------------------------------------------------------------------------------------"

# Run the Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook -i ../1.setup-docker/inventory.ini main.yml --ask-vault-pass

echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Checking Playbook"
echo "---------------------------------------------------------------------------------------------------------------------"

echo "Checking Ansible playbook..."
ansible all -i ../1.setup-docker/inventory.ini --ask-vault-pass -m shell -a "docker images -a" -b

echo "---------------------------------------------------------------------------------------------------------------------"
echo "                                        Delete Images folders"
echo "---------------------------------------------------------------------------------------------------------------------"

echo "Delete Images folders"
echo "Do you want to execute the Ansible command? (y/n)"
read confirmation

if [ "$confirmation" = "y" ]; then
  echo "Deleting Images Folder..."
  ansible workers -i ../1.setup-docker/inventory.ini --ask-vault-pass -m shell -a "rm -rf ./images" -b
else
  echo "Ansible command not executed."
fi
