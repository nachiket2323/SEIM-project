!/bin/bash
# =========================================
#  Wazuh High Severity Alert Test Script
# =========================================
# Triggers alerts with level > 3 for n8n testing
# =========================================

echo "🚨 Starting HIGH SEVERITY Wazuh alert tests..."

# 1️⃣ Multiple failed SSH attempts (Level 10)
echo "➡️ Triggering SSH brute force alerts..."
for i in {1..5}; do
    sshpass -p "badpass$i" ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no fakeuser$i@localhost exit 2>/dev/null
    sleep 1
done

# 2️⃣ Multiple sudo failures (Level 5)
echo "➡️ Triggering sudo authentication failures..."
sudo -k
for i in {1..3}; do
    echo "wrongpass$i" | sudo -S whoami 2>/dev/null
    sleep 1
done

# 3️⃣ Rootkit detection simulation (Level 7)
echo "➡️ Creating suspicious rootkit-like files..."
sudo mkdir -p /tmp/.hidden
echo "suspicious_content" | sudo tee /tmp/.hidden/backdoor > /dev/null
echo "rootkit_signature" | sudo tee /dev/shm/rk_file > /dev/null

# 4️⃣ Critical file modification (Level 12)
echo "➡️ Modifying critical system files..."
sudo touch /etc/passwd.bak
sudo sh -c 'echo "# ALERT TEST" >> /etc/shadow'
sudo chmod 777 /tmp/critical_test 2>/dev/null || sudo touch /tmp/critical_test && sudo chmod 777 /tmp/critical_test

# 5️⃣ Malware signature simulation (Level 15)
echo "➡️ Creating malware-like signatures..."
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' | sudo tee /tmp/eicar_test > /dev/null
echo "Trojan.Generic.Signature" | sudo tee /tmp/malware_sim > /dev/null

# 6️⃣ Port scan simulation (Level 6)
echo "➡️ Simulating port scan activity..."
nmap -sS localhost -p 1-100 > /dev/null 2>&1 &

echo "✅ High severity alerts triggered!"
echo "Check Wazuh Manager: tail -f /var/ossec/logs/alerts/alerts.json"
echo "Monitor n8n executions for webhook alerts."
