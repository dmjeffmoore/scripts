#!/bin/sh

# --- CONFIGURATION ---
ZONE_ID="your_zone_id"
TOKEN="your_api_token"
DOMAIN="example.com"
IP_FILE="/tmp/last_ip.txt" # Where to store the last known IP
# ---------------------

# 1. Get current public IP
CURRENT_IP=$(dig +short myip.opendns.com @resolver4.opendns.com)

if [ -z "$CURRENT_IP" ]; then
    echo "Error: Could not resolve public IP."
    exit 1
fi

# 2. Check if IP has changed since last run
if [ -f "$IP_FILE" ]; then
    LAST_IP=$(cat "$IP_FILE")
    if [ "$CURRENT_IP" = "$LAST_IP" ]; then
        echo "IP ($CURRENT_IP) has not changed. Skipping update."
        exit 0
    fi
fi

echo "IP changed from $LAST_IP to $CURRENT_IP. Updating Cloudflare..."

# 3. Get Record ID
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DOMAIN&type=A" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
    echo "Error: Could not find record for $DOMAIN"
    exit 1
fi

# 4. Perform the Update
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     --data "{
        \"type\": \"A\",
        \"name\": \"$DOMAIN\",
        \"content\": \"$CURRENT_IP\",
        \"ttl\": 3600,
        \"proxied\": true,
        \"comment\": \"Alpine LXC Auto-Update\"
     }")

# 5. Success Check & Save IP
if echo "$RESPONSE" | jq -e '.success' > /dev/null; then
    echo "Update successful."
    echo "$CURRENT_IP" > "$IP_FILE"
else
    echo "Update failed: $(echo "$RESPONSE" | jq -r '.errors[0].message')"
    exit 1
fi
