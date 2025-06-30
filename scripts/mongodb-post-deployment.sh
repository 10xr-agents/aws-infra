#!/bin/bash
# Post-deployment script for MongoDB replica set configuration

set -e

echo "MongoDB Post-Deployment Configuration Script"
echo "==========================================="

# Get outputs from Terraform
echo "Getting MongoDB cluster information from Terraform..."

# You'll need to run this from the environments/qa directory
PRIMARY_IP=$(terraform output -raw mongodb_primary_endpoint | cut -d':' -f1)
REPLICA_SET_NAME=$(terraform output -raw mongodb_replica_set_name)
ADMIN_USERNAME=$(terraform output -raw mongodb_admin_username)

# Get all MongoDB endpoints
ENDPOINTS=$(terraform output -json mongodb_endpoints | jq -r '.[]')

echo ""
echo "Primary MongoDB Instance: $PRIMARY_IP"
echo "Replica Set Name: $REPLICA_SET_NAME"
echo ""

# Function to check if MongoDB is ready
check_mongodb_ready() {
    local host=$1
    echo "Checking if MongoDB is ready on $host..."
    for i in {1..30}; do
        if mongo --host "$host" --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            echo "MongoDB is ready on $host"
            return 0
        fi
        echo "Waiting for MongoDB to be ready... ($i/30)"
        sleep 10
    done
    echo "MongoDB did not become ready on $host"
    return 1
}

# Check if primary is ready
check_mongodb_ready "$PRIMARY_IP"

echo ""
echo "Please enter the MongoDB admin password:"
read -s ADMIN_PASSWORD
echo ""

# Add secondary nodes to replica set
echo "Adding secondary nodes to replica set..."

# Connect to primary and add other nodes
mongo --host "$PRIMARY_IP" -u "$ADMIN_USERNAME" -p "$ADMIN_PASSWORD" --authenticationDatabase admin <<EOF
// Get current replica set configuration
var config = rs.conf();
print("Current replica set members: " + config.members.length);

// Get list of all endpoints
var endpoints = db.adminCommand({ getParameter: 1, "net.bindIp": 1 });

// Add secondary nodes if not already present
var allEndpoints = ${ENDPOINTS};
allEndpoints.forEach(function(endpoint, index) {
    var host = endpoint;
    var found = false;

    config.members.forEach(function(member) {
        if (member.host === host) {
            found = true;
        }
    });

    if (!found && index > 0) {
        print("Adding member: " + host);
        rs.add({
            host: host,
            priority: 1,
            votes: 1
        });
    }
});

// Show final status
printjson(rs.status());
EOF

echo ""
echo "Replica set configuration complete!"
echo ""
echo "You can now connect to MongoDB using:"
echo "mongo 'mongodb://$ADMIN_USERNAME:<password>@$(echo $ENDPOINTS | tr ' ' ',')/$REPLICA_SET_NAME?replicaSet=$REPLICA_SET_NAME&authSource=admin'"
echo ""
echo "To create application users, connect to the primary and run:"
echo "use your_database_name"
echo "db.createUser({"
echo "  user: 'appuser',"
echo "  pwd: 'apppassword',"
echo "  roles: [{ role: 'readWrite', db: 'your_database_name' }]"
echo "})"