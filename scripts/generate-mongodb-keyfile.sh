#!/bin/bash
# Script to generate a secure MongoDB keyfile content

echo "Generating MongoDB keyfile content..."

# Generate 756 bytes of random data and encode as base64
# This creates a secure key for MongoDB replica set authentication
KEYFILE_CONTENT=$(openssl rand -base64 756 | tr -d '\n')

echo ""
echo "MongoDB Keyfile Content (copy this to your terraform.tfvars):"
echo "==========================================================="
echo "mongodb_keyfile_content = \"$KEYFILE_CONTENT\""
echo "==========================================================="
echo ""
echo "This keyfile content should be kept secure and not committed to version control."
echo "Consider using AWS Secrets Manager or environment variables for production deployments."