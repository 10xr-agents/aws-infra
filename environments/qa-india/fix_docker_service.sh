#!/bin/bash

# fix_docker_service.sh - Fix Docker permissions and restart LiveKit service
# Run this script to fix the current Docker permission issues

set -e

echo "=============================================="
echo "Fixing Docker Permissions and LiveKit Service"
echo "=============================================="
echo "Timestamp: $(date)"
echo ""

# Fix Docker permissions
echo "1. Fixing Docker permissions..."
echo "==============================="

# Add current user to docker group
sudo usermod -aG docker $USER

# Check if docker group exists and user is in it
if groups $USER | grep -q docker; then
    echo "✓ User $USER is in docker group"
else
    echo "✗ Adding user $USER to docker group"
    sudo usermod -aG docker $USER
fi

# Restart Docker service to ensure it's running
echo "Restarting Docker service..."
sudo systemctl restart docker
sleep 5

# Check Docker status
echo "Docker service status:"
sudo systemctl status docker --no-pager

echo ""

# Fix Docker Compose symlink
echo "2. Fixing Docker Compose..."
echo "==========================="
if [ ! -f /usr/bin/docker-compose ]; then
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

# Test Docker access
echo "Testing Docker access..."
if sudo docker ps > /dev/null 2>&1; then
    echo "✓ Docker is accessible with sudo"
else
    echo "✗ Docker is not accessible even with sudo"
    exit 1
fi

echo ""

# Fix LiveKit service
echo "3. Fixing LiveKit Service..."
echo "============================"

cd /opt/livekit-proxy

# Stop any existing containers
echo "Stopping existing containers..."
sudo docker-compose down 2>/dev/null || true

# Check if we can authenticate with ECR
echo "Testing ECR authentication..."
if aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 761018882607.dkr.ecr.us-east-1.amazonaws.com; then
    echo "✓ ECR authentication successful"
else
    echo "✗ ECR authentication failed"
    exit 1
fi

# Pull the image
echo "Pulling Docker image..."
sudo docker-compose pull

# Start the service
echo "Starting LiveKit service..."
sudo docker-compose up -d

# Wait for service to start
echo "Waiting for service to start..."
sleep 30

# Check container status
echo "Container status:"
sudo docker-compose ps

# Show logs
echo "Recent logs:"
sudo docker-compose logs --tail=20

echo ""

# Test connectivity
echo "4. Testing Connectivity..."
echo "=========================="

# Test if port 9000 is listening
if netstat -tlnp | grep -q ":9000"; then
    echo "✓ Port 9000 is listening"
else
    echo "✗ Port 9000 is not listening"
fi

# Test local connectivity
echo "Testing local HTTP connectivity:"
if curl -f http://localhost:9000/ 2>/dev/null; then
    echo "✓ Port 9000 HTTP is accessible"
else
    echo "✗ Port 9000 HTTP failed - checking what's running..."
    sudo docker logs $(sudo docker-compose ps -q) || echo "No container logs available"
fi

# Test alternative endpoints
echo "Testing health endpoints:"
curl -f http://localhost:9000/health 2>/dev/null && echo "✓ /health endpoint works" || echo "✗ /health endpoint failed"
curl -f http://localhost:9000/api/v1/management/health 2>/dev/null && echo "✓ /api/v1/management/health endpoint works" || echo "✗ /api/v1/management/health endpoint failed"

echo ""

# Fix Nginx
echo "5. Fixing Nginx..."
echo "=================="

# Test Nginx configuration
sudo nginx -t && echo "✓ Nginx configuration is valid" || echo "✗ Nginx configuration has errors"

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl status nginx --no-pager

# Test Nginx health
curl -f http://localhost:80/health 2>/dev/null && echo "✓ Nginx health check passed" || echo "✗ Nginx health check failed"

echo ""

# Create a simple test for the ubuntu user
echo "6. Setting up for ubuntu user..."
echo "================================"

# Create a script that ubuntu user can run without sudo
cat > /home/ubuntu/check_service.sh << 'EOF'
#!/bin/bash
echo "Checking LiveKit service status (run this after logout/login):"
echo "Container status:"
docker-compose -f /opt/livekit-proxy/docker-compose.yml ps 2>/dev/null || echo "Need to logout/login first for docker group to take effect"

echo "Testing connectivity:"
curl -f http://localhost:9000/ 2>/dev/null && echo "✓ Service is responding" || echo "✗ Service not responding"

echo "Checking what's listening:"
netstat -tlnp | grep -E ':(80|443|8080|9000)' || echo "No services listening on expected ports"
EOF

chmod +x /home/ubuntu/check_service.sh
chown ubuntu:ubuntu /home/ubuntu/check_service.sh

echo ""

# Summary
echo "7. Summary..."
echo "============="
echo "✓ Docker permissions fixed"
echo "✓ LiveKit service restarted"
echo "✓ Nginx restarted"
echo ""
echo "IMPORTANT: You need to logout and login again for docker group changes to take effect."
echo "After logout/login, you can run:"
echo "  ./check_service.sh"
echo ""
echo "If the service is still not working, check:"
echo "1. Container logs: sudo docker-compose -f /opt/livekit-proxy/docker-compose.yml logs"
echo "2. Container status: sudo docker-compose -f /opt/livekit-proxy/docker-compose.yml ps"
echo "3. What's listening: netstat -tlnp | grep 9000"
echo ""

# Create a restart script for future use
cat > /home/ubuntu/restart_livekit.sh << 'EOF'
#!/bin/bash
cd /opt/livekit-proxy
echo "Restarting LiveKit service..."
sudo docker-compose down
sudo docker-compose up -d
sleep 10
sudo docker-compose ps
sudo docker-compose logs --tail=10
EOF

chmod +x /home/ubuntu/restart_livekit.sh
chown ubuntu:ubuntu /home/ubuntu/restart_livekit.sh

echo "Created restart_livekit.sh for easy service management"
echo ""
echo "=============================================="
echo "Fix script completed!"
echo "=============================================="