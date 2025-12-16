#!/bin/bash
set -e

# This script runs after infrastructure provisioning to:
# 1. Register the ContextOnlyLanguageModel in the ML workspace
# 2. Create the online deployment
# 3. Retrieve the endpoint key
# 4. Update the .env file with endpoint details
# 5. Retrieve Azure OpenAI API key and update .env

echo "Running post-provision hook..."

# Get variables from azd environment
ML_WORKSPACE_NAME=$(azd env get-value ML_WORKSPACE_NAME)
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP)
ML_ENDPOINT_NAME=$(azd env get-value ML_ENDPOINT_NAME)
SUBSCRIPTION_ID=$(azd env get-value AZURE_SUBSCRIPTION_ID)
AI_PROJECT_NAME=$(azd env get-value AI_PROJECT_NAME)
GPT_CHAT_DEPLOYMENT_NAME=$(azd env get-value GPT_CHAT_DEPLOYMENT_NAME)
AZURE_AISEARCH_NAME=$(azd env get-value AZURE_AISEARCH_NAME)
AZURE_KEY_VAULT_NAME=$(azd env get-value AZURE_KEY_VAULT_NAME)
AZURE_KEY_VAULT_URI=$(azd env get-value AZURE_KEY_VAULT_URI)
BING_SEARCH_ENDPOINT=$(azd env get-value BING_SEARCH_ENDPOINT)
BING_SEARCH_NAME=$(azd env get-value BING_SEARCH_NAME)

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "$(dirname "$(dirname "$0")")")" && pwd)"

# OpenAI keys are managed separately via AZURE_OPENAI_KEY environment variable
# No need to retrieve them from Cognitive Services account

# Check if ML workspace is enabled
if [ -z "$ML_WORKSPACE_NAME" ] || [ "$ML_WORKSPACE_NAME" = "" ]; then
    echo "ML Workspace not enabled, skipping ML model registration"
    
    # Update .env file with AI Foundry variables only
    if [ -n "$AI_PROJECT_NAME" ]; then
        ENV_FILE="$REPO_ROOT/.env"
        echo "Updating .env file with AI Foundry details at: $ENV_FILE"
        
        {
            # Preserve existing variables if file exists
            if [ -f "$ENV_FILE" ]; then
                grep -v "^AI_PROJECT_NAME=" "$ENV_FILE" | \
                grep -v "^GPT52_CHAT_DEPLOYMENT_NAME=" || true
            fi
            
            # Add AI Foundry variables
            echo "AI_PROJECT_NAME=$AI_PROJECT_NAME"
            echo "GPT52_CHAT_DEPLOYMENT_NAME=$GPT52_CHAT_DEPLOYMENT_NAME"
        } > "$ENV_FILE.tmp"
        
        mv "$ENV_FILE.tmp" "$ENV_FILE"
        echo "✅ .env file updated with AI Foundry details"
    fi
    
    exit 0
fi

echo "ML Workspace Name: $ML_WORKSPACE_NAME"
echo "Resource Group: $RESOURCE_GROUP"
echo "ML Endpoint Name: $ML_ENDPOINT_NAME"
echo "Subscription ID: $SUBSCRIPTION_ID"

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "$(dirname "$(dirname "$0")")")" && pwd)"
echo "Repository root: $REPO_ROOT"

# Register the model and create deployment using Python script
echo "Registering model and creating deployment..."

# Run the Python script
python3 "$REPO_ROOT/scripts/register_ml_model.py" \
    --subscription-id "$SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$ML_WORKSPACE_NAME" \
    --endpoint-name "$ML_ENDPOINT_NAME" \
    --model-source "$REPO_ROOT/src/context_only_model.py" \
    --deployment-path "$REPO_ROOT/deployment" \
    --model-name "ContextOnlyLanguageModel" \
    --model-version "1" \
    --deployment-name "contextonly-deployment" \
    --instance-type "Standard_DS2_v2" \
    --instance-count 1

if [ $? -ne 0 ]; then
    echo "Failed to register model or create deployment"
    exit 1
fi

# Get the endpoint key
echo "Retrieving endpoint key..."
ML_ENDPOINT_KEY=$(az ml online-endpoint get-credentials \
    --name "$ML_ENDPOINT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$ML_WORKSPACE_NAME" \
    --query primaryKey -o tsv)

if [ -z "$ML_ENDPOINT_KEY" ]; then
    echo "Warning: Failed to retrieve endpoint key"
    ML_ENDPOINT_KEY="<key-not-available>"
fi

# Get the scoring URI
echo "Retrieving scoring URI..."
ML_ENDPOINT_SCORING_URI=$(az ml online-endpoint show \
    --name "$ML_ENDPOINT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$ML_WORKSPACE_NAME" \
    --query scoring_uri -o tsv)

if [ -z "$ML_ENDPOINT_SCORING_URI" ]; then
    echo "Warning: Failed to retrieve scoring URI"
    ML_ENDPOINT_SCORING_URI="<uri-not-available>"
fi

echo "Endpoint details retrieved"

# Update .env file in the root of the repository
ENV_FILE="$REPO_ROOT/.env"
echo "Updating .env file at: $ENV_FILE"

# Create or update .env file
{
    # Preserve existing variables if file exists
    if [ -f "$ENV_FILE" ]; then
        grep -v "^AI_PROJECT_NAME=" "$ENV_FILE" | \
        grep -v "^AZURE_AISEARCH_NAME=" | \
        grep -v "^AZURE_KEY_VAULT_NAME=" | \
        grep -v "^AZURE_KEY_VAULT_URI=" | \
        grep -v "^BING_SEARCH_ENDPOINT=" | \
        grep -v "^BING_SEARCH_NAME=" | \
        grep -v "^GPT_CHAT_DEPLOYMENT_NAME=" | \
        grep -v "^ML_ENDPOINT_KEY=" | \
        grep -v "^ML_ENDPOINT_NAME=" | \
        grep -v "^ML_ENDPOINT_SCORING_URI=" | \
        grep -v "^ML_WORKSPACE_NAME=" | \
        grep -v "^OPENAI_ACCOUNT_NAME=" | \
        grep -v "^OPENAI_API_KEY=" | \
        grep -v "^OPENAI_ENDPOINT=" || true
    fi
    
    # Add variables in alphabetical order
    if [ -n "$OPENAI_ACCOUNT_NAME" ]; then
        echo "AI_PROJECT_NAME=$AI_PROJECT_NAME"
    fi
    echo "AZURE_AISEARCH_NAME=$AZURE_AISEARCH_NAME"
    echo "AZURE_KEY_VAULT_NAME=$AZURE_KEY_VAULT_NAME"
    echo "AZURE_KEY_VAULT_URI=$AZURE_KEY_VAULT_URI"
    echo "BING_SEARCH_ENDPOINT=$BING_SEARCH_ENDPOINT"
    echo "BING_SEARCH_NAME=$BING_SEARCH_NAME"
    if [ -n "$OPENAI_ACCOUNT_NAME" ]; then
        echo "GPT_CHAT_DEPLOYMENT_NAME=$GPT_CHAT_DEPLOYMENT_NAME"
    fi
    echo "ML_ENDPOINT_KEY=$ML_ENDPOINT_KEY"
    echo "ML_ENDPOINT_NAME=$ML_ENDPOINT_NAME"
    echo "ML_ENDPOINT_SCORING_URI=$ML_ENDPOINT_SCORING_URI"
    echo "ML_WORKSPACE_NAME=$ML_WORKSPACE_NAME"
    if [ -n "$OPENAI_ACCOUNT_NAME" ]; then
        echo "OPENAI_ACCOUNT_NAME=$OPENAI_ACCOUNT_NAME"
        echo "OPENAI_API_KEY=$OPENAI_API_KEY"
        echo "OPENAI_ENDPOINT=$OPENAI_ENDPOINT"
    fi
} > "$ENV_FILE.tmp"

mv "$ENV_FILE.tmp" "$ENV_FILE"

# Create Azure AI Search index and ingest content
echo "Setting up Azure AI Search index..."

# Get Azure AI Search keys
AZURE_AISEARCH_ADMIN_KEY=$(az search admin-key show \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$AZURE_AISEARCH_NAME" \
    --query primaryKey -o tsv)

AZURE_AISEARCH_KEY=$(az search query-key list \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$AZURE_AISEARCH_NAME" \
    --query [0].key -o tsv)

# Update .env with search keys
if [ -f "$ENV_FILE" ]; then
    grep -v "^AZURE_AISEARCH_ADMIN_KEY=" "$ENV_FILE" | \
    grep -v "^AZURE_AISEARCH_KEY=" > "$ENV_FILE.tmp"
    mv "$ENV_FILE.tmp" "$ENV_FILE"
fi

echo "AZURE_AISEARCH_ADMIN_KEY=$AZURE_AISEARCH_ADMIN_KEY" >> "$ENV_FILE"
echo "AZURE_AISEARCH_KEY=$AZURE_AISEARCH_KEY" >> "$ENV_FILE"

# Create search index
echo "Creating search index..."
cd "$REPO_ROOT/scripts"
python3 create.py
if [ $? -eq 0 ]; then
    echo "✅ Search index created successfully"
else
    echo "⚠️  Warning: Failed to create search index"
fi

# Ingest content (only if PDF exists)
if [ -f "$REPO_ROOT/content/tricare-provider-handbook.pdf" ]; then
    echo "Ingesting content into search index..."
    python3 ingest.py
    if [ $? -eq 0 ]; then
        echo "✅ Content ingested successfully"
    else
        echo "⚠️  Warning: Failed to ingest content"
    fi
else
    echo "⚠️  PDF file not found, skipping content ingestion"
fi

cd "$REPO_ROOT"

echo "✅ Post-provision hook completed successfully"
echo "ML Endpoint URL: $ML_ENDPOINT_SCORING_URI"
if [ -n "$OPENAI_ENDPOINT" ]; then
    echo "OpenAI Endpoint: $OPENAI_ENDPOINT"
    echo "GPT Chat Deployment: $GPT_CHAT_DEPLOYMENT_NAME"
fi
echo "Azure AI Search: $AZURE_AISEARCH_NAME"
echo ".env file updated with endpoint details"
