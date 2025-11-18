#!/usr/bin/env python3
import json
import requests
import time
import os

# === Configuration ===
#WEBHOOK_URL = "http://192.168.1.2:5678/webhook/9b21b294-0e0f-4b16-8c59-ba45177c5e25" 
WEBHOOK_URL = "http://192.168.1.7:5678/webhook-test/wazuh-alert"  # Your n8n webhook URL
#WEBHOOK_URL = "http://192.168.1.2:5678/webhook/wazuh-alert"  # <-- use this when workflow is active
ALERT_FILE = "/var/ossec/logs/alerts/alerts.json"  # Wazuh alerts log file
BATCH_SIZE = 10         # Number of alerts per batch
BATCH_INTERVAL = 30     # Seconds between batch sends

def read_new_lines(file_path, last_pos):
    """Read new lines from a file since last known position."""
    try:
        with open(file_path, "r") as f:
            f.seek(last_pos)
            lines = f.readlines()
            new_pos = f.tell()
            return lines, new_pos
    except FileNotFoundError:
        print(f"⚠ File not found: {file_path}")
        return [], last_pos
    except Exception as e:
        print(f"✗ Error reading {file_path}: {e}")
        return [], last_pos

def send_batch(batch):
    """Send batch of alerts to n8n webhook."""
    if not batch:
        return
    try:
        print(f"🚀 Sending batch of {len(batch)} alerts...")
        response = requests.post(WEBHOOK_URL, json=batch, timeout=15)
        if response.status_code == 200:
            print("✓ Batch sent successfully\n")
        else:
            print(f"✗ Failed to send batch: {response.status_code} {response.text}\n")
    except Exception as e:
        print(f"✗ Error sending batch: {e}\n")

def main():
    print("=== Wazuh → n8n Batch Forwarder Started ===")
    print(f"Webhook: {WEBHOOK_URL}")
    print(f"Source: {ALERT_FILE}")
    print(f"Batch size: {BATCH_SIZE}, Interval: {BATCH_INTERVAL}s")

    last_pos = 0
    batch = []
    last_send_time = time.time()

    while True:
        lines, last_pos = read_new_lines(ALERT_FILE, last_pos)
        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                alert = json.loads(line)
                batch.append(alert)
            except json.JSONDecodeError:
                # If line is invalid JSON, wrap it in a raw message
                batch.append({"raw": line})

            # Send if batch is full
            if len(batch) >= BATCH_SIZE:
                send_batch(batch)
                batch = []
                last_send_time = time.time()

        # Send remaining alerts periodically even if batch not full
        if time.time() - last_send_time >= BATCH_INTERVAL and batch:
            send_batch(batch)
            batch = []
            last_send_time = time.time()

        time.sleep(5)

if __name__ == "__main__":
    main()
