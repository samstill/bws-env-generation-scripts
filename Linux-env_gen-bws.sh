#!/bin/bash

# Set the secret IDs and their corresponding environment variable keys
declare -A secretMappings=(
    # Add your secrets here with format: [bitwarden_secret_id]="ENV_VAR_NAME"
    # Examples:
    ["f8074057-7835-47a8-ac06-b2b9013"]="Test_Key"
    # Add more secrets below by uncommenting and replacing with your values:
    # ["your-secret-id-here"]="SECRET_NAME"
    # ["another-secret-id"]="ANOTHER_ENV_VAR"
)

# Path to the .env file
envFilePath=".env"

# Create empty temporary file
touch "$envFilePath.tmp"

# Read existing .env file (if it exists) and preserve entries not managed by this script
if [ -f "$envFilePath" ]; then
    # Get all env var names that we're managing
    managedVars=""
    for secretId in "${!secretMappings[@]}"; do
        varName="${secretMappings[$secretId]}"
        if [ -z "$managedVars" ]; then
            managedVars="^$varName="
        else
            managedVars="$managedVars\|^$varName="
        fi
    done
    
    # Copy all unmanaged entries to the temporary file
    if [ -n "$managedVars" ]; then
        grep -v "$managedVars" "$envFilePath" > "$envFilePath.tmp" 2>/dev/null
    else
        # If no managed vars (unlikely), just copy the file
        cp "$envFilePath" "$envFilePath.tmp"
    fi
fi

# Track errors
errorOccurred=false

# Fetch the secrets using bws and jq and add to the .env file
for secretId in "${!secretMappings[@]}"; do
    secretValue=$(bws secret get "$secretId" | jq -r '.value' 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to fetch the secret for ${secretMappings[$secretId]}. Make sure bws and jq are installed." >&2
        errorOccurred=true
        continue
    fi
    
    envVarName="${secretMappings[$secretId]}"
    echo "$envVarName=$secretValue" >> "$envFilePath.tmp"
    echo "✓ Successfully set $envVarName"
done

# Only replace the .env file if no errors occurred
if [ "$errorOccurred" = false ]; then
    mv "$envFilePath.tmp" "$envFilePath"
    echo "✅ All secrets have been set in .env successfully."
else
    echo "⚠️ Some secrets could not be fetched. The .env file has not been updated."
    rm "$envFilePath.tmp"
    exit 1
fi
