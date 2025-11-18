#!/bin/bash
# =========================================
#  Wazuh Agent (mintos) - Alert Test Script
# =========================================
# This script safely generates multiple types
# of alerts so you can test your Wazuh → n8n webhook integration.
# =========================================

echo "🚀 Starting Wazuh alert test sequence..."

# 1️⃣ Generate Wazuh built-in test alert
echo "➡️  Generating Wazuh built-in test alert..."
/var/ossec/bin/agent_control -t
sleep 2

# 2️⃣ Simulate failed sudo attempt
echo "➡️  Simulating failed sudo password..."
sudo -k  # clear cached credentials
(echo "wrongpassword" | sudo -S ls >/dev/null 2>&1)
sleep 2

# 3️⃣ Simulate SSH failed login attempt (localhost)
echo "➡️  Simulating failed SSH login..."
sshpass -p "wrongpass" ssh -o StrictHostKeyChecking=no wronguser@localhost "exit" >/dev/null 2>&1
sleep 2

# 4️⃣ Simulate file integrity modification
echo "➡️  Simulating file modification in /etc..."
sudo sh -c 'echo "# Wazuh test change" >> /etc/hosts'
sleep 2

# 5️⃣ Simulate fake malware file detection
echo "➡️  Simulating suspicious file creation..."
echo "Trojan test signature - malicious pattern" | sudo tee /tmp/fake_trojan.txt >/dev/null
sleep 2

echo "✅ All test alerts triggered!"
echo "Now check on Wazuh Manager (Kali):"
echo "   tail -f /var/ossec/logs/alerts/alerts.json"
echo "And in n8n → Executions tab to verify received alerts."
