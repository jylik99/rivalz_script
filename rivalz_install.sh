#!/bin/bash

echo -e "\033[1;32m"
echo "======================================"
echo "    Rivalz Node Installation Script   "
echo "======================================"
echo -e "\033[0m"

check_command() {
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31mError: $1 failed\033[0m"
        exit 1
    fi
}

echo -e "\033[1;34m\nUpdating system packages...\033[0m"
sudo apt update
check_command "System update"

echo -e "\033[1;34m\nUpgrading system packages...\033[0m"
sudo apt upgrade -y
check_command "System upgrade"

echo -e "\033[1;34m\nInstalling Node.js 20.x...\033[0m"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
check_command "Node.js repository setup"

sudo apt install -y nodejs
check_command "Node.js installation"

echo -e "\033[1;34m\nInstalling Rivalz CLI...\033[0m"
npm i -g rivalz-node-cli
check_command "Rivalz CLI installation"

cat > /root/apply_disk_fix.sh << 'EOF'
#!/bin/bash

FILE="/usr/lib/node_modules/rivalz-node-cli/node_modules/systeminformation/lib/filesystem.js"

find_file_path() {
  local search_path="$1"
  find "$search_path" -type f -name "filesystem.js" 2>/dev/null | grep "systeminformation/lib/filesystem.js" | head -n 1
}

if [ ! -f "$FILE" ]; then
  echo "File not found at $FILE. Attempting to locate it..."
  FILE=$(find_file_path "/usr/lib")
  
  if [ -z "$FILE" ]; then
    FILE=$(find_file_path "/usr/local/lib")
  fi
  
  if [ -z "$FILE" ]; then
    FILE=$(find_file_path "/opt")
  fi
  
  if [ -z "$FILE" ]; then
    FILE=$(find_file_path "$HOME/.nvm")
  fi
  
  if [ -z "$FILE" ]; then
    echo "Error: filesystem.js not found. Make sure npm is installed and the file path is correct."
    exit 1
  fi

  echo "File found at $FILE"
fi

TMP_FILE=$(mktemp)

ORIGINAL_LINE="devices = outJSON.blockdevices.filter(item => { return (item.type === 'disk') && item.size > 0 && (item.model !== null || (item.mountpoint === null && item.label === null && item.fstype === null && item.parttype === null && item.path && item.path.indexOf('/ram') !== 0 && item.path.indexOf('/loop') !== 0 && item['disc-max'] && item['disc-max'] !== 0)); });"
NEW_LINE="devices = outJSON.blockdevices.filter(item => { return (item.type === 'disk') && item.size > 0 }).sort((a, b) => b.size - a.size);"

while IFS= read -r line
do
  if [[ "$line" == *"$ORIGINAL_LINE"* ]]; then
    echo "$NEW_LINE" >> "$TMP_FILE"
  else
    echo "$line" >> "$TMP_FILE"
  fi
done < "$FILE"

mv "$TMP_FILE" "$FILE"

echo "Disk fix applied successfully"
EOF

chmod +x /root/apply_disk_fix.sh

cat > /root/rivalz_auto_update.sh << 'EOF'
#!/bin/bash

echo "Stopping Rivalz node..."
pkill -f "rivalz run"
sleep 5

echo "Starting update..."
rivalz update-version
sleep 5

echo "Applying disk fix..."
/root/apply_disk_fix.sh
sleep 2

echo "Starting Rivalz node..."
rivalz run &

echo "Update cycle completed"
EOF

chmod +x /root/rivalz_auto_update.sh

cat > /etc/systemd/system/rivalz-auto-update.service << 'EOF'
[Unit]
Description=Rivalz Node Auto Update Service
After=network.target

[Service]
Type=oneshot
ExecStart=/root/rivalz_auto_update.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/rivalz-auto-update.timer << 'EOF'
[Unit]
Description=Run Rivalz auto-update every 3 hours

[Timer]
OnBootSec=15min
OnUnitActiveSec=3h

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable rivalz-auto-update.timer
systemctl start rivalz-auto-update.timer

echo -e "\033[1;34m\nApplying initial disk fix...\033[0m"
/root/apply_disk_fix.sh

echo -e "\033[1;33m"
echo "Starting Rivalz node..."
echo "Auto-updates will run every 3 hours"
echo "To check logs use: journalctl -u rivalz-auto-update"
echo -e "\033[0m"

rivalz run