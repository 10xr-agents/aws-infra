#!/bin/bash
# ECR Docker Image Verification Script
# Run with sudo bash verify-ecr-docker.sh

set -e

echo "==============================================" 
echo "ECR Docker Image Verification"
echo "==============================================" 
echo "Timestamp: $(date)"
echo ""

# Step 1: Check AWS CLI version and credentials
echo "1. Checking AWS CLI and credentials..."
echo "==============================="
aws --version

# Check if AWS credentials are available
echo "Testing AWS credentials..."
if aws sts get-caller-identity; then
    echo "✓ AWS credentials are valid"
else
    echo "✗ AWS credentials are missing or invalid"
    exit 1
fi

# Step 2: Verify ECR permissions 
echo ""
echo "2. Verifying ECR permissions..."
echo "==========================="

# Try to list repositories in both regions
echo "Testing ECR access in us-east-1 (source region):"
if aws ecr describe-repositories --region us-east-1 | grep -q "repositoryName"; then
    echo "✓ Can list ECR repositories in us-east-1"
else
    echo "✗ Cannot list ECR repositories in us-east-1"
fi

echo "Testing ECR access in ap-south-1 (local region):"
if aws ecr describe-repositories --region ap-south-1 2>/dev/null | grep -q "repositoryName"; then
    echo "✓ Can list ECR repositories in ap-south-1"
else
    echo "✓ No repositories in ap-south-1 (this is expected for cross-region)"
fi

# Step 3: Verify the specific image exists
echo ""
echo "3. Verifying image exists..."
echo "============================"

REPO="10xr-agents/livekit-proxy-service"
TAG="0.1.0"

echo "Checking if image $REPO:$TAG exists in us-east-1..."
if aws ecr describe-images --repository-name $REPO --image-ids imageTag=$TAG --region us-east-1 2>/dev/null; then
    echo "✓ Image exists and is accessible"
else
    echo "✗ Image does not exist or is not accessible"
    echo "   Possible issues:"
    echo "   - Repository name may be incorrect"
    echo "   - Tag may be incorrect"
    echo "   - May lack permissions"
    exit 1
fi

# Step 4: Test ECR authentication
echo ""
echo "4. Testing ECR authentication..."
echo "==============================="

ECR_REGISTRY="761018882607.dkr.ecr.us-east-1.amazonaws.com"

echo "Authenticating with ECR..."
if aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY; then
    echo "✓ ECR authentication successful"
else
    echo "✗ ECR authentication failed"
    exit 1
fi

# Step 5: Test Docker image pull
echo ""
echo "5. Testing Docker image pull..."
echo "=============================="

IMAGE_URL="$ECR_REGISTRY/$REPO:$TAG"
echo "Pulling image: $IMAGE_URL"
if docker pull $IMAGE_URL; then
    echo "✓ Image pull successful"
    
    # Get image details
    echo "Image details:"
    docker inspect $IMAGE_URL | grep -E 'Id|RepoTags|Created|DockerVersion|Architecture|Os'
else
    echo "✗ Image pull failed"
    exit 1
fi

# Step 6: Test Docker run
echo ""
echo "6. Testing Docker container startup..."
echo "===================================="

echo "Starting container to test basic functionality..."
CONTAINER_ID=$(docker run -d -p 9000:9000 -e SERVICE_PORT=9000 -e REGION=india $IMAGE_URL)

# Wait for container to start up
echo "Waiting for container to start up..."
sleep 10

# Check container status
echo "Container status:"
if docker ps | grep -q $CONTAINER_ID; then
    echo "✓ Container is running"
    
    # Display container details
    docker ps --filter "id=$CONTAINER_ID" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
else
    echo "✗ Container failed to start or crashed"
    echo "Container logs:"
    docker logs $CONTAINER_ID
    exit 1
fi

# Step 7: Test container connectivity
echo ""
echo "7. Testing container connectivity..."
echo "=================================="

# Test if port 9000 is listening
if netstat -tlnp | grep -q ":9000"; then
    echo "✓ Port 9000 is listening"
else
    echo "✗ Port 9000 is not listening"
fi

# Test HTTP connectivity
echo "Testing HTTP connectivity..."
for ENDPOINT in "/" "/health" "/api/v1/management/health"; do
    echo -n "Testing endpoint $ENDPOINT: "
    if curl -s -f http://localhost:9000$ENDPOINT >/dev/null; then
        echo "✓ Success"
    else
        echo "✗ Failed"
    fi
done

# Get container logs
echo ""
echo "Container logs:"
docker logs $CONTAINER_ID --tail 20

# Step 8: Clean up
echo ""
echo "8. Cleaning up..."
echo "================="

echo "Stopping and removing test container..."
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID

echo ""
echo "==============================================" 
echo "Verification completed!"
echo "==============================================" 
if docker ps | grep -q "livekit-proxy"; then
    echo "✓ LiveKit proxy is running in a separate container"
    docker ps | grep "livekit-proxy"
else
    echo "Note: No LiveKit proxy container is currently running"
    echo "Run the fix_docker_service.sh script to start the service"
fi