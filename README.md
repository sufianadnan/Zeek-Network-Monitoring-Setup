# Zeek Network Monitoring Setup

## Introduction
This script automates the setup process for Zeek Network Monitoring on your Ubuntu system. Zeek is a powerful network analysis tool that helps you monitor and analyze network traffic. This README provides instructions on how to use the script and explains the steps it performs.

### Author
- Sufian Adnan

## Prerequisites
Before running this script, make sure you have:

- A fresh Ubuntu installation (Tested on Ubuntu 20.04, 22.04, and 23.04).
- Root privileges (you can use `sudo`).
- An active internet connection.

## Usage
1. **Download the Script:**

   You can download the script directly or clone this GitHub repository to your system.

2. **Make the Script Executable:**

   Open your terminal and navigate to the directory where you downloaded or cloned the script. Run the following command:

   ```bash
   chmod +x setup-zeek.sh
Run the Script:

Execute the script with root privileges using the sudo command:
sudo ./setup-zeek.sh
The script will ask for your network interface name (e.g., ens33). Enter the appropriate interface name when prompted.

Wait for Setup to Complete:

The script will perform the following tasks:

- Update and upgrade system packages.
- Install necessary packages (e.g., zeek, zeekctl, zkg).
- Configure Zeek for network monitoring.
- Start Zeek services.
- Please be patient as the setup process may take some time.

Verify Zeek Status:

After the setup is complete, you can verify the status of Zeek by running:
```bash
sudo zeekctl status
