#!/bin/bash
set -e

# Variables from Terraform
MONGODB_VERSION="${mongodb_version}"
REPLICA_SET_NAME="${replica_set_name}"
NODE_INDEX="${node_index}"
TOTAL_NODES="${total_nodes}"
ADMIN_USERNAME="${mongodb_admin_username}"
ADMIN_PASSWORD="${mongodb_admin_password}"
KEYFILE_CONTENT="${mongodb_keyfile_content}"
ENABLE_MONITORING="${enable_monitoring}"
DATA_VOLUME_DEVICE="${data_volume_device}"
CLUSTER_NAME="${cluster_name}"

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting MongoDB setup..."
echo "MongoDB Version: $MONGODB_VERSION"
echo "Replica Set: $REPLICA_SET_NAME"
echo "Node Index: $NODE_INDEX"
echo "Expected device: $DATA_VOLUME_DEVICE"

# Update system
apt-get update
apt-get upgrade -y

# Install prerequisites
apt-get install -y gnupg curl wget software-properties-common

# Import MongoDB GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-$${MONGODB_VERSION}.asc | apt-key add -

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/$${MONGODB_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-$${MONGODB_VERSION}.list

# Update package list
apt-get update

# Install MongoDB
apt-get install -y mongodb-org

# Install CloudWatch agent if monitoring is enabled
if [ "$ENABLE_MONITORING" = "true" ]; then
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i -E ./amazon-cloudwatch-agent.deb
    rm ./amazon-cloudwatch-agent.deb
fi

# FIXED: Smart device detection for NVMe vs traditional EBS
echo "Detecting attached EBS volume..."

# Function to find the actual device name
find_data_device() {
    # List all block devices
    echo "Available block devices:"
    lsblk

    # For NVMe instances, EBS volumes appear as /dev/nvme*n*
    # The root volume is typically nvme0n1, so data volume would be nvme1n1, nvme2n1, etc.

    # Method 1: Look for unmounted volumes that aren't the root
    for device in /dev/nvme*n1; do
        if [ -e "$device" ]; then
            # Skip if it's the root device
            if ! mount | grep -q "$device"; then
                # Check if it's not part of the root filesystem
                if ! lsblk "$device" | grep -q "/"; then
                    echo "Found unmounted NVMe device: $device"
                    echo "$device"
                    return 0
                fi
            fi
        fi
    done

    # Method 2: Look for traditional EBS device names
    for device in /dev/xvd[f-z] /dev/sd[f-z]; do
        if [ -e "$device" ]; then
            if ! mount | grep -q "$device"; then
                echo "Found unmounted traditional device: $device"
                echo "$device"
                return 0
            fi
        fi
    done

    # Method 3: Use AWS CLI to identify the volume
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    if command -v aws >/dev/null 2>&1; then
        # Get the volume ID attached to this instance (excluding root volume)
        VOLUME_INFO=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName!=`/dev/sda1` && DeviceName!=`/dev/xvda`]' --output text 2>/dev/null)
        if [ -n "$VOLUME_INFO" ]; then
            echo "Found volume via AWS API: $VOLUME_INFO"
        fi
    fi

    return 1
}

# Wait for EBS volume to be attached and find it
echo "Waiting for data volume to be attached..."
ACTUAL_DEVICE=""
MAX_WAIT=300  # 5 minutes
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # Try to find the device
    if ACTUAL_DEVICE=$(find_data_device); then
        echo "Found data device: $ACTUAL_DEVICE"
        break
    fi

    echo "Waiting for data volume... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 5
    WAIT_COUNT=$((WAIT_COUNT + 5))
done

if [ -z "$ACTUAL_DEVICE" ]; then
    echo "ERROR: Could not find data volume after $MAX_WAIT seconds"
    echo "Available devices:"
    lsblk
    exit 1
fi

# Use the detected device
DATA_DEVICE="$ACTUAL_DEVICE"
echo "Using device: $DATA_DEVICE"

# Check if the volume needs formatting
echo "Checking if volume needs formatting..."
if [ "$(file -s $DATA_DEVICE)" = "$DATA_DEVICE: data" ]; then
    echo "Formatting data volume with XFS..."
    mkfs -t xfs $DATA_DEVICE
else
    echo "Volume already formatted or contains data"
fi

# Create mount point
mkdir -p /data/mongodb

# Mount the volume
echo "Mounting $DATA_DEVICE to /data/mongodb"
mount $DATA_DEVICE /data/mongodb

# Add to fstab for persistent mounting (use UUID for reliability)
DEVICE_UUID=$(blkid -s UUID -o value $DATA_DEVICE)
if [ -n "$DEVICE_UUID" ]; then
    echo "UUID=$DEVICE_UUID /data/mongodb xfs defaults,nofail 0 2" >> /etc/fstab
else
    echo "$DATA_DEVICE /data/mongodb xfs defaults,nofail 0 2" >> /etc/fstab
fi

# Verify mount
df -h /data/mongodb
echo "Mount successful!"

# Set permissions
chown -R mongodb:mongodb /data/mongodb

# Create necessary directories
mkdir -p /data/mongodb/db
mkdir -p /data/mongodb/logs
mkdir -p /etc/mongodb
chown -R mongodb:mongodb /data/mongodb

# Create keyfile for replica set authentication if provided
if [ ! -z "$KEYFILE_CONTENT" ]; then
    echo "$KEYFILE_CONTENT" > /etc/mongodb/keyfile
    chmod 400 /etc/mongodb/keyfile
    chown mongodb:mongodb /etc/mongodb/keyfile
fi

# Configure MongoDB
cat > /etc/mongod.conf <<EOF
# MongoDB configuration file

storage:
  dbPath: /data/mongodb/db
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 2

systemLog:
  destination: file
  logAppend: true
  path: /data/mongodb/logs/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

replication:
  replSetName: $REPLICA_SET_NAME

security:
  authorization: enabled
EOF

# Add keyfile to config if provided
if [ ! -z "$KEYFILE_CONTENT" ]; then
    echo "  keyFile: /etc/mongodb/keyfile" >> /etc/mongod.conf
fi

# Start MongoDB
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to start
echo "Starting MongoDB service..."
sleep 10

# Check if MongoDB started successfully
if ! systemctl is-active --quiet mongod; then
    echo "ERROR: MongoDB failed to start. Checking logs..."
    systemctl status mongod
    tail -50 /data/mongodb/logs/mongod.log
    exit 1
fi

echo "MongoDB started successfully!"

# Initialize replica set on the first node
if [ "$NODE_INDEX" = "0" ]; then
    echo "Initializing replica set..."

    # Get instance metadata
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

    # Wait for MongoDB to be ready
    sleep 15

    # Initialize replica set (without authentication first)
    mongosh --eval "
    rs.initiate({
        _id: '$REPLICA_SET_NAME',
        members: [
            { _id: 0, host: '$PRIVATE_IP:27017', priority: 2 }
        ]
    })
    "

    # Wait for replica set to initialize
    echo "Waiting for replica set to initialize..."
    sleep 15

    # Create admin user
    echo "Creating admin user..."
    mongosh admin --eval "
    db.createUser({
        user: '$ADMIN_USERNAME',
        pwd: '$ADMIN_PASSWORD',
        roles: [
            { role: 'root', db: 'admin' },
            { role: 'clusterAdmin', db: 'admin' }
        ]
    })
    "

    echo "Admin user created successfully!"
fi

# Configure CloudWatch agent if enabled
if [ "$ENABLE_MONITORING" = "true" ]; then
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/data/mongodb/logs/mongod.log",
            "log_group_name": "/aws/ec2/mongodb/$CLUSTER_NAME",
            "log_stream_name": "{instance_id}-mongodb",
            "retention_in_days": 7
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "MongoDB",
    "metrics_collected": {
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DiskUsedPercent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/data/mongodb"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MemoryUsedPercent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

    # Start CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -s \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
fi

# Set up automatic backups via cron (simple snapshot script)
cat > /usr/local/bin/mongodb-backup.sh <<'EOF'
#!/bin/bash
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
VOLUME_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].BlockDeviceMappings[?DeviceName!=`/dev/sda1` && DeviceName!=`/dev/xvda`].Ebs.VolumeId' --output text | head -1)
SNAPSHOT_DESC="MongoDB backup - $INSTANCE_ID - $(date +%Y-%m-%d-%H-%M-%S)"
aws ec2 create-snapshot --volume-id $VOLUME_ID --description "$SNAPSHOT_DESC" --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=mongodb-backup},{Key=Instance,Value=$INSTANCE_ID}]"
EOF

chmod +x /usr/local/bin/mongodb-backup.sh

# Add to crontab for daily backups at 2 AM
echo "0 2 * * * /usr/local/bin/mongodb-backup.sh" | crontab -

echo "MongoDB setup complete!"
echo "Final status:"
systemctl status mongod --no-pager
echo "Listening on port 27017:"
ss -tln | grep 27017