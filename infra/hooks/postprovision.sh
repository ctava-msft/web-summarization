#!/bin/bash
set -e

# Post-provision hook for Azure AI Foundry deployment
# The azd CLI automatically populates .env from bicep outputs
# This script can be used for additional post-deployment tasks

echo "Running post-provision hook..."

# Get variables from azd environment
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP)
FOUNDRY_NAME=$(azd env get-value AI_PROJECT_NAME)
MODEL_DEPLOYMENT=$(azd env get-value AZURE_AI_MODEL_DEPLOYMENT_NAME)

echo "✅ Azure AI Foundry deployment completed"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Foundry Account: $FOUNDRY_NAME"
echo "   Model Deployment: $MODEL_DEPLOYMENT"
echo ""
echo "All environment variables have been set in .env"
echo "You can now run: python query.py"

exit 0