#!/bin/sh

# --- CONFIGURATION ---
ZONE_ID="your_zone_id_here"
TOKEN="your_api_token_here"
DOMAIN="example.com"
# ---------------------

# 1. Check for dependencies (Alpine specific)
for cmd in curl jq dig; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "Error: $cmd is not installed. Run: apk add curl jq bind-tools"
        exit 1
    fi
done

# 2. Get the current Public IP
PUBLIC_IP=$(dig +short myip.opendns.com @resolver4.opendns.com)

if [ -z "$PUBLIC_IP" ]; then
    echo "Error: Could not retrieve public IP."
    exit 1
fi

echo "Current Public IP: $PUBLIC_IP"

# 3. Get the Record ID for the domain
echo "Fetching Record ID for $DOMAIN..."
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$DOMAIN&type=A" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# Check if we actually got an ID
if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
    echo "Error: Could not find an 'A' record for $DOMAIN in Cloudflare."
    exit 1
fi

echo "Found Record ID: $RECORD_ID"

# 4. Update the record
echo "Updating Cloudflare..."
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     --data "{
        \"type\": \"A\",
        \"name\": \"$DOMAIN\",
        \"content\": \"$PUBLIC_IP\",
        \"ttl\": 3600,
        \"proxied\": true,
        \"comment\": \"LXC Auto-Update\"
     }")

# 5. Final Success Check
SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
    echo "Done! $DOMAIN updated to $PUBLIC_IP"
else
    MESSAGE=$(echo "$RESPONSE" | jq -r '.errors[0].message')
    echo "Update failed: $MESSAGE"
    exit 1
fi
