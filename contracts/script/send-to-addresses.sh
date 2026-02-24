#!/bin/bash

# Script to send 0.00005 ETH to each address in addresses.csv
# Usage: ./script/send-to-addresses.sh

set -e

RPC_URL="https://arb-mainnet.g.alchemy.com/v2/WtGzKM0NAY_Mr3rAYlykQWnzPF6JbcHy"
WALLET="shells"
AMOUNT="0.00005ether"
CSV_FILE="addresses.csv"

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    echo "Error: $CSV_FILE not found!"
    echo "Please create a $CSV_FILE file with one address per line."
    exit 1
fi

# Count total addresses
total=$(wc -l < "$CSV_FILE" | tr -d ' ')
echo "Found $total addresses in $CSV_FILE"
echo "Sending $AMOUNT to each address..."
echo ""

# Counter for progress
counter=0

# Read each line from the CSV file
while IFS= read -r address || [ -n "$address" ]; do
    # Skip empty lines and lines starting with #
    if [ -z "$address" ] || [[ "$address" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Remove any whitespace and carriage returns
    address=$(echo "$address" | tr -d '[:space:]')
    
    # Skip if address is empty after cleaning
    if [ -z "$address" ]; then
        continue
    fi
    
    counter=$((counter + 1))
    echo "[$counter/$total] Sending $AMOUNT to $address..."
    
    # Send the transaction
    cast send "$address" \
        --value "$AMOUNT" \
        --rpc-url "$RPC_URL" \
        --account "$WALLET"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully sent to $address"
    else
        echo "✗ Failed to send to $address"
    fi
    
    echo ""
    
    # Optional: add a small delay between transactions to avoid rate limiting
    sleep 1
done < "$CSV_FILE"

echo "Done! Processed $counter addresses."
