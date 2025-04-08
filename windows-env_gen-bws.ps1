# Set the secret IDs and their corresponding environment variable keys
$secretMappings = @{

# Write your Secrets here with bitwarden_secret_id = secret_key
    "4a87313c-fca1-49e7-91e7-b2b90128d4b5" = "API_KEY";
    "f8074057-7835-47a8-ac06-b2b9013" = "Test_Key";
}

# Path to the .env file
$envFilePath = ".env"

# Read existing .env file (if it exists)
$existingLines = @()
if (Test-Path $envFilePath) {
    $existingLines = Get-Content $envFilePath
}

# Clean the .env file by removing existing environment variables
$existingLines = $existingLines | Where-Object { $_ -notmatch "^(API_KEY|Test_Key)=" }

# Create a new array to store environment variables
$newEnvContent = @()

# Fetch the secrets using bws and jq and add to the new content array
foreach ($secretId in $secretMappings.Keys) {
    try {
        $secretValue = (bws secret get $secretId | jq -r '.value')
    } catch {
        Write-Host "❌ Failed to fetch the secret. Make sure bws and jq are installed." -ForegroundColor Red
        exit 1
    }

    $envVarName = $secretMappings[$secretId]
    $newEnvContent += "$envVarName=$secretValue"
}

# Combine the new environment variables with any existing content
$finalContent = $newEnvContent + $existingLines

# Write back to the .env file
$finalContent | Set-Content -Encoding UTF8 $envFilePath

Write-Host "✅ All secrets have been set in .env successfully." -ForegroundColor Green
