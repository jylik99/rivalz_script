#!/bin/bash

echo -e "\033[1;32m"
echo "======================================"
echo "    Rivalz Node Uninstall Script     "
echo "======================================"
echo -e "\033[0m"

echo -e "\033[1;34m\nStopping Rivalz node and services...\033[0m"
pkill -f "rivalz run"
systemctl stop rivalz-auto-update.timer
systemctl disable rivalz-auto-update.timer
systemctl stop rivalz-auto-update.service

echo -e "\033[1;34m\nRemoving services...\033[0m"
rm -f /etc/systemd/system/rivalz-auto-update.service
rm -f /etc/systemd/system/rivalz-auto-update.timer
systemctl daemon-reload

echo -e "\033[1;34m\nRemoving scripts...\033[0m"
rm -f /root/apply_disk_fix.sh
rm -f /root/rivalz_auto_update.sh

echo -e "\033[1;34m\nUninstalling Rivalz CLI...\033[0m"
npm uninstall -g rivalz-node-cli

echo -e "\033[1;34m\nRemoving Node.js...\033[0m"
sudo apt-get remove nodejs -y
sudo apt-get purge nodejs -y
sudo apt-get autoremove -y

echo -e "\033[1;34m\nRemoving Node.js repository...\033[0m"
sudo rm -rf /etc/apt/sources.list.d/nodesource.list*

echo -e "\033[1;32m"
echo "======================================"
echo "Rivalz node has been uninstalled!"
echo "======================================"
echo -e "\033[0m"