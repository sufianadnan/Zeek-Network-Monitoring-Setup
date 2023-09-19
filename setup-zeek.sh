#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color

# Greeting message with the username
username=$(whoami)
echo -e "Hello, ${YELLOW}$username!${NC} Let's get this setup for you"

error_exit() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  error_exit "This script must be run with ${YELLOW}sudo${NC}."
fi

# Update and upgrade packages silently
echo -e "Updating necessary packages..."

if apt-get update -y &> /dev/null; then
    echo -e "${GREEN}Package update and upgrade completed successfully.${NC}"
else
    error_exit "${RED}Error occurred during package update and upgrade.${NC}"
fi

# Install required packages silently
echo -e "Installing necessary packages..."
if apt install -y wget curl ethtool nano &> /dev/null; then
    echo -e "${GREEN}Necessary packages installed successfully.${NC}"
else
    error_exit "${RED}Failed to install required packages.${NC}"
fi

# Check if ethtool is installed; if not, install it
if ! command -v ethtool &> /dev/null; then
    echo -e "ethtool is not installed. Installing..."
    sudo apt-get install ethtool -y &> /dev/null
fi

if ! command -v ifconfig &> /dev/null; then
    echo -e "ifconfig is not installed. Installing net-tools..."
    sudo apt-get install net-tools -y &> /dev/null
fi
# Prompt the user for the network interface name
read -p "Enter the network interface name (e.g., ens33): " interface_name

# Enable promiscuous mode
ifconfig "$interface_name" promisc

# Disable checksum offloading
ethtool --offload "$interface_name" tx off rx off &> /dev/null

echo -e "Promiscuous mode is ${GREEN}enabled${NC} and checksum offloading is ${GREEN}disabled${NC} for ${YELLOW}$interface_name${NC}."

# Determine the Ubuntu version
ubuntu_version=$(lsb_release -r -s)

# Add Zeek repository and GPG key based on Ubuntu version
echo -e "Adding Zeek repository and GPG key for Ubuntu $ubuntu_version..."
case $ubuntu_version in
    20.04)
        repo_version="20.04"
        ;;
    22.04)
        repo_version="22.04"
        ;;
    23.04)
        repo_version="23.04"
        ;;
    *)
        error_exit "${RED}Unsupported Ubuntu version: $ubuntu_version${NC}"
        ;;
esac

echo "deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_${repo_version}/ /" | tee /etc/apt/sources.list.d/security:zeek.list > /dev/null
curl -fsSL "https://download.opensuse.org/repositories/security:zeek/xUbuntu_${repo_version}/Release.key" | gpg --dearmor | tee "/etc/apt/trusted.gpg.d/security_zeek.gpg" > /dev/null

# Update package manager
# Update package manager silently
echo -e "Updating package manager..."
if apt update &> /dev/null; then
    echo -e "${GREEN}Package manager updated successfully.${NC}"
else
    error_exit "${RED}Failed to update package lists.${NC}"
fi

echo "Installing Zeek and ZKG..."
apt install -y zeek zeekctl zkg || error_exit "Failed to install Zeek and ZKG."
# Path to the Zeek binary directory

if ! command -v zkg &> /dev/null; then
    error_exit "ZKG is not installed. Please install ZKG before running this script."
fi

# Path to the Zeek binary directory
zeek_bin_path="/opt/zeek/bin"

export PATH=$PATH:/opt/zeek/bin

# Check Zeek version
zeek_version=$(zeek --version)
echo -e "${GREEN}$zeek_version is installed.${NC}"

# Change directory to Zeek site
cd /opt/zeek/share/zeek/site

# Clone the file-extraction repository
git clone http://github.com/hosom/file-extraction file-extraction

# Add file-extraction to local.zeek
echo "@load file-extraction/scripts/" >> local.zeek

# Create the extracted directory
mkdir -p /opt/zeek/extracted/

# Path to the Zeek file-extraction config file
config_zeek_file="/opt/zeek/share/zeek/site/file-extraction/scripts/config.zeek"

# Define the new value for redef path
new_path_value='/opt/zeek/extracted/'
export PATH=$PATH:/opt/zeek/bin
echo 'export PATH=$PATH:/opt/zeek/bin' >> ~/.bashrc

# Check if the config.zeek file exists
if [ -f "$config_zeek_file" ]; then
    # Use sed to find and replace the redef path line
    sed -i "s|^redef path = .*|redef path = \"$new_path_value\";|" "$config_zeek_file"
    echo -e "Updated redef path in ${YELLOW}$config_zeek_file${NC} to ${YELLOW}$new_path_value${NC}"
else
    error_exit "${RED}Error: $config_zeek_file does not exist.${NC}"
fi

# Path to the Zeek node configuration file
node_cfg_file="/opt/zeek/etc/node.cfg"

# Define the new 'interface' line
new_interface_line="interface=ens33"

# Check if the node.cfg file exists
if [ -f "$node_cfg_file" ]; then
    # Use sed to find and replace the 'interface' line
    sed -i "s/^interface=.*/$new_interface_line/" "$node_cfg_file"
    echo -e "Updated 'interface' line in ${YELLOW}$node_cfg_file${NC} to ${YELLOW}$new_interface_line${NC}"
else
    error_exit "${RED}Error: $node_cfg_file does not exist.${NC}"
fi

# Perform Zeek control commands and check for errors
echo -e "Performing Zeek control commands..."
if zeekctl check &> /dev/null; then
    echo -e "${GREEN}Zeek control check completed successfully.${NC}"
else
    error_exit "${RED}Failed to run 'zeekctl check'.${NC}"
fi

if zeekctl deploy &> /dev/null; then
    echo -e "${GREEN}Zeek control deploy completed successfully.${NC}"
else
    error_exit "${RED}Failed to run 'zeekctl deploy'.${NC}"
fi

if zeekctl start &> /dev/null; then
    echo -e "${GREEN}Zeek control start completed successfully.${NC}"
else
    error_exit "${RED}Failed to run 'zeekctl start'.${NC}"
fi

if zeekctl status; then
    echo -e "${GREEN}Zeek control status checked.${NC}"
else
    error_exit "${RED}Failed to run 'zeekctl status'.${NC}"
fi

echo -e "${GREEN}Setup completed successfully.${NC}"
# Exit with success
exit 0
