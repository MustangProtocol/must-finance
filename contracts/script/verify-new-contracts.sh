#!/bin/bash

# Verification script for newly deployed contracts (e.g. SaviorToken)
# Usage: ./script/verify-new-contracts.sh [path_to_broadcast_json]
# If no path is provided, uses broadcast/DeployLiquity2.s.sol/5464/run-latest.json
# Set RPC_URL, VERIFIER, VERIFIER_URL to override (e.g. for different chains)

RPC_URL="${RPC_URL:-https://sagaevm.jsonrpc.sagarpc.io}"
VERIFIER="${VERIFIER:-blockscout}"
VERIFIER_URL="${VERIFIER_URL:-https://api-sagaevm.sagaexplorer.io/api/}"
BROADCAST_JSON="${1:-broadcast/DeployLiquity2.s.sol/5464/run-latest.json}"

# Map new contract names to their source file paths
get_contract_path() {
    local contract_name=$1
    case "$contract_name" in
        "SaviorToken")
            echo "src/SaviorToken.sol:SaviorToken"
            ;;
        *)
            echo ""
            ;;
    esac
}

verify_contract() {
    local contract_name=$1
    local contract_address=$2
    local contract_path=$3

    if [ -z "$contract_path" ]; then
        echo "⚠ Skipping $contract_name at $contract_address (no source path mapping)"
        return 1
    fi

    echo "=========================================="
    echo "Verifying $contract_name"
    echo "Address: $contract_address"
    echo "Path: $contract_path"
    echo "=========================================="

    forge verify-contract \
        --rpc-url "$RPC_URL" \
        --verifier "$VERIFIER" \
        --verifier-url "$VERIFIER_URL" \
        "$contract_address" \
        "$contract_path"

    if [ $? -eq 0 ]; then
        echo "✓ Successfully verified $contract_name at $contract_address"
    else
        echo "✗ Failed to verify $contract_name at $contract_address"
    fi
    echo ""
}

# New contracts to verify (add more as needed)
NEW_CONTRACTS=("SaviorToken")

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq first."
    exit 1
fi

# Resolve path relative to script dir: script is in contracts/script/, broadcast is in contracts/broadcast/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTRACTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ "$BROADCAST_JSON" != /* ]]; then
    BROADCAST_JSON="$CONTRACTS_DIR/$BROADCAST_JSON"
fi

# Check if broadcast JSON exists
if [ ! -f "$BROADCAST_JSON" ]; then
    echo "Error: $BROADCAST_JSON not found"
    echo "Usage: $0 [path_to_broadcast_json]"
    exit 1
fi

# Extract matching contracts from JSON
found_any=0
for contract_name in "${NEW_CONTRACTS[@]}"; do
    addresses=$(jq -r --arg name "$contract_name" \
        '.transactions[] | select(.contractName == $name) | .contractAddress' \
        "$BROADCAST_JSON" 2>/dev/null)

    if [ -z "$addresses" ]; then
        continue
    fi

    while IFS= read -r contract_address; do
        [ -z "$contract_address" ] && continue
        found_any=1
        contract_path=$(get_contract_path "$contract_name")
        verify_contract "$contract_name" "$contract_address" "$contract_path"
        sleep 1
    done <<< "$addresses"
done

if [ $found_any -eq 0 ]; then
    echo "No new contracts (${NEW_CONTRACTS[*]}) found in $BROADCAST_JSON"
    echo "Ensure the deployment broadcast includes these contracts."
    exit 1
fi
