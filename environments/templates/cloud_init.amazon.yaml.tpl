#cloud-config
# This file is used as a user-data script to start a VM
# It'll upload configs to the right location and install LiveKit as a systemd service
# LiveKit will be started automatically at machine startup
repo_update: true
repo_upgrade: all

packages:
  - docker
  - amazon-cloudwatch-agent
  - nvidia-cuda-toolkit
  - libcuda1
  - libavcodec-extra
  - libavformat-extra
  - libsndfile1
  - libgstreamer1.0-0
  - gstreamer1.0-plugins-base
  - gstreamer1.0-plugins-good
  - gstreamer1.0-plugins-bad
  - gstreamer1.0-plugins-ugly
  - gstreamer1.0-plugins-bad-free
  - gstreamer1.0-plugins-bad-freeworld
  - gstreamer1.0-libav
  - ffmpeg
  - mesa-libGL
  - xorg-x11-server-Xvfb
  - awscli
  - openssl
  - libssl-dev

bootcmd:
  - mkdir -p /opt/livekit/caddy_data
  - mkdir -p /usr/local/bin

write_files:

  - path: /etc/rc.local
    permissions: '0755'
    content: |
      #!/bin/bash
      export AWS_DEFAULT_REGION=${aws_region}
      mkdir -p /etc/caddy/certs
      aws s3 cp s3://${cert_bucket}/cert.pem /etc/caddy/certs/private_cert.pem
      aws s3 cp s3://${cert_bucket}/key.pem /etc/caddy/certs/encrypted_key.pem
      aws s3 cp s3://${cert_bucket}/chain.pem /etc/caddy/certs/chain.pem
      aws s3 cp s3://${cert_bucket}/root_ca_crt.pem /etc/caddy/certs/root_ca_crt.pem
      cat /etc/caddy/certs/private_cert.pem /etc/caddy/certs/chain.pem >> /etc/caddy/certs/cert.pem
      cat /etc/caddy/certs/cert.pem /etc/caddy/certs/root_ca_crt.pem >> /etc/caddy/certs/cert.pem
      PASSPHRASE="live_kit_tls_pass_phrase"
      openssl rsa -in /etc/caddy/certs/encrypted_key.pem -out /etc/caddy/certs/key.pem -passin pass:$PASSPHRASE
      chmod 755 /etc/caddy/certs/key.pem
      chmod 755 /etc/caddy/certs/cert.pem

  - path: /opt/livekit/livekit.yaml
    content: |
      port: 7880
      bind_addresses:
          - ""
      rtc:
          tcp_port: 7881
          port_range_start: 50000
          port_range_end: 60000
          use_external_ip: true
          enable_loopback_candidate: false
      redis:
          address: ${redis_address}
          username: ${redis_username}
          password: ${redis_password}
          db: 0
          use_tls: false
          sentinel_master_name: ""
          sentinel_username: ""
          sentinel_password: ""
          sentinel_addresses: []
          cluster_addresses: []
          max_redirects: null
      turn:
          enabled: true
          domain: ${turn_domain}
          tls_port: 5349
          udp_port: 3478
          external_tls: true
      ingress:
          rtmp_base_url: rtmp://${livekit_domain}:1935/x
          whip_base_url: https://${whip_domain}/w
      keys:
          ${api_key}: ${api_secret}
      webhook:
        api_key: ${api_key}
        urls:
          - ${webhook_events_url}

  - path: /opt/livekit/caddy.yaml
    content: |
      logging:
        logs:
          default:
            level: INFO
      storage:
        "module": "file_system"
        "root": "/data"
      apps:
        tls:
          certificates:
            load_files:
              - certificate: /etc/caddy/certs/cert.pem
                key: /etc/caddy/certs/key.pem

        layer4:
          servers:
            main:
              listen: [":443"]
              routes:
                - match:
                  - tls:
                      sni:
                        - "${turn_domain}"
                  handle:
                    - handler: tls
                    - handler: proxy
                      upstreams:
                        - dial: ["localhost:5349"]
                - match:
                    - tls:
                        sni:
                          - "${livekit_domain}"
                  handle:
                    - handler: tls
                      connection_policies:
                        - alpn: ["http/1.1"]
                    - handler: proxy
                      upstreams:
                        - dial: ["localhost:7880"]
                - match:
                    - tls:
                        sni:
                          - "${whip_domain}"
                  handle:
                    - handler: tls
                      connection_policies:
                        - alpn: ["http/1.1"]
                    - handler: proxy
                      upstreams:
                        - dial: ["localhost:8080"]
      

  - path: /opt/livekit/update_ip.sh
    content: |
      #!/usr/bin/env bash
      ip=`ip addr show |grep "inet " |grep -v 127.0.0. |head -1|cut -d" " -f6|cut -d/ -f1`
      sed -i.orig -r "s/\\\"(.+)(\:5349)/\\\"$ip\2/" /opt/livekit/caddy.yaml
      

  - path: /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    content: |
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
                  "file_path": "/var/log/livekit/livekit.log",
                  "log_group_name": "/ec2/livekit",
                  "log_stream_name": "{instance_id}"
                },
                {
                  "file_path": "/var/log/caddy/caddy.log",
                  "log_group_name": "/ec2/caddy",
                  "log_stream_name": "{instance_id}"
                },
                {
                  "file_path": "/var/log/livekit/egress.log",
                  "log_group_name": "/ec2/livekit-egress",
                  "log_stream_name": "{instance_id}"
                },
                {
                  "file_path": "/var/log/livekit/ingress.log",
                  "log_group_name": "/ec2/livekit-ingress",
                  "log_stream_name": "{instance_id}"
                }
              ]
            }
          }
        }
      }

  - path: /opt/livekit/docker-compose.yaml
    content: |
      # This docker-compose requires host networking, which is only available on Linux
      # This compose will not function correctly on Mac or Windows
      services:
        caddy:
          image: livekit/caddyl4
          container_name: caddy
          command: run --config /etc/caddy.yaml --adapter yaml
          restart: unless-stopped
          network_mode: "host"
          volumes:
            - ./caddy.yaml:/etc/caddy.yaml
            - ./caddy_data:/data
            - /etc/caddy/certs/cert.pem:/etc/caddy/certs/cert.pem
            - /etc/caddy/certs/key.pem:/etc/caddy/certs/key.pem
            - /etc/caddy/certs/chain.pem:/etc/caddy/certs/chain.pem
          logging:
            driver: "json-file"
            options:
              max-size: "100m"
              max-file: "5"
        livekit:
          image: livekit/livekit-server:latest
          container_name: livekit
          command: --config /etc/livekit.yaml
          restart: unless-stopped
          network_mode: "host"
          volumes:
            - ./livekit.yaml:/etc/livekit.yaml
          logging:
            driver: "json-file"
            options:
              max-size: "100m"
              max-file: "5"
        egress:
          image: livekit/egress:latest
          container_name: egress
          restart: unless-stopped
          environment:
            - EGRESS_CONFIG_FILE=/etc/egress.yaml
          network_mode: "host"
          volumes:
            - ./egress.yaml:/etc/egress.yaml
          cap_add:
            - CAP_SYS_ADMIN
          logging:
            driver: "json-file"
            options:
              max-size: "100m"
              max-file: "5"
        ingress:
          image: livekit/ingress:latest
          container_name: ingress
          restart: unless-stopped
          environment:
            - INGRESS_CONFIG_FILE=/etc/ingress.yaml
          network_mode: "host"
          volumes:
            - ./ingress.yaml:/etc/ingress.yaml
          logging:
            driver: "json-file"
            options:
              max-size: "100m"
              max-file: "5"
      

  - path: /etc/systemd/system/livekit-docker.service
    content: |
      [Unit]
      Description=LiveKit Server Container
      After=docker.service
      Requires=docker.service
      
      [Service]
      LimitNOFILE=500000
      Restart=always
      WorkingDirectory=/opt/livekit
      # Shutdown container (if running) when unit is started
      ExecStartPre=/usr/local/bin/docker-compose -f docker-compose.yaml down
      ExecStart=/usr/local/bin/docker-compose -f docker-compose.yaml up
      ExecStop=/usr/local/bin/docker-compose -f docker-compose.yaml down
      
      [Install]
      WantedBy=multi-user.target

  - path: /etc/systemd/system/amazon-cloudwatch-agent.service
    content: |
      [Unit]
         Description=Amazon CloudWatch Agent
         After=network.target

         [Service]
         Type=simple
         ExecStart=/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
         Restart=on-failure
         RestartSec=60s

         [Install]
         WantedBy=multi-user.target

  - path: /opt/livekit/egress.yaml
    content: |
      redis:
          address: ${redis_address}
          username: ${redis_username}
          password: ${redis_password}
          db: 0
          use_tls: false
          sentinel_master_name: ""
          sentinel_username: ""
          sentinel_password: ""
          sentinel_addresses: []
          cluster_addresses: []
          max_redirects: null
      api_key: ${api_key}
      api_secret: ${api_secret}
      ws_url: wss://${livekit_domain}
      

  - path: /opt/livekit/ingress.yaml
    content: |
      redis:
          address: ${redis_address}
          username: ${redis_username}
          password: ${redis_password}
          db: 0
          use_tls: false
          sentinel_master_name: ""
          sentinel_username: ""
          sentinel_password: ""
          sentinel_addresses: []
          cluster_addresses: []
          max_redirects: null
      api_key: ${api_key}
      api_secret: ${api_secret}
      ws_url: wss://${livekit_domain}
      rtmp_port: 1935
      whip_port: 8080
      http_relay_port: 9090
      logging:
          json: false
          level: ""
      development: false
      rtc_config:
          udp_port: 7885
          use_external_ip: true
          enable_loopback_candidate: false
      

runcmd:
  - amazon-linux-extras install -y epel
  - yum install -y epel-release
  - yum install -y ffmpeg gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly gstreamer1-libav
  - yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  - yum install -y --enablerepo=epel gstreamer1-plugins-bad-freeworld
  - yum install -y awscli openssl openssl-devel
  - yum install -y mesa-libGL xorg-x11-server-Xvfb
  - echo "INSTALLED EPEL LIBRARIES"
  - rm -rf /var/cache/yum

  # Install NVIDIA driver and CUDA
  - amazon-linux-extras install -y nvidia
  - sudo yum install -y --disableplugin=priorities nvidia-driver nvidia-driver-libs nvidia-driver-cuda
  - sudo yum install -y --disableplugin=priorities cuda-drivers
  - echo "INSTALLED CUDA NVIDIA DRIVERS LIBRARIES"
  - rm -rf /var/cache/yum

  # Download and install CUDA Toolkit
  - wget https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda-repo-rhel7-11-7-local-11.7.1_515.65.01-1.x86_64.rpm
  - rpm -i cuda-repo-rhel7-11-7-local-11.7.1_515.65.01-1.x86_64.rpm
  - yum clean all
  - yum install --disableplugin=priorities -y cuda
  - echo "INSTALLED CUDA NVIDIA REPO LIBRARIES"
  - rm -rf /var/cache/yum

  # Set up CUDA environment variables
  - echo 'export PATH=/usr/local/cuda-11.7/bin:$PATH' >> /etc/profile.d/cuda.sh
  - echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64:$LD_LIBRARY_PATH' >> /etc/profile.d/cuda.sh
  - source /etc/profile.d/cuda.sh
  - ldconfig
  - echo "ADDED LD LIBRARY PATH"
  - rm -rf /var/cache/yum

  - /etc/rc.local
  - curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  - chmod 755 /usr/local/bin/docker-compose
  - chmod 755 /opt/livekit/update_ip.sh
  - /opt/livekit/update_ip.sh
  - ldconfig
  - rm -rf /var/cache/yum

  # Start CloudWatch agent
  - systemctl enable amazon-cloudwatch-agent
  - systemctl start amazon-cloudwatch-agent
  # Ensure log directories exist
  - mkdir -p /var/log/livekit
  - mkdir -p /var/log/caddy
  # Set up log rotation for Docker containers
  - echo '#!/bin/sh' > /etc/logrotate.d/docker-containers
  - echo '/var/lib/docker/containers/*/*.log {' >> /etc/logrotate.d/docker-containers
  - echo '  rotate 7' >> /etc/logrotate.d/docker-containers
  - echo '  daily' >> /etc/logrotate.d/docker-containers
  - echo '  compress' >> /etc/logrotate.d/docker-containers
  - echo '  size=100M' >> /etc/logrotate.d/docker-containers
  - echo '  missingok' >> /etc/logrotate.d/docker-containers
  - echo '  delaycompress' >> /etc/logrotate.d/docker-containers
  - echo '  copytruncate' >> /etc/logrotate.d/docker-containers
  - echo '}' >> /etc/logrotate.d/docker-containers
  - echo "STARTED CLOUD WATCH AGENTS"
  - rm -rf /var/cache/yum

  # Start services
  - systemctl enable docker
  - systemctl start docker
  - systemctl enable livekit-docker
  - systemctl start livekit-docker
  - echo "STARTED DOCKER PROCESS"

  # Define wait_for_containers function
  - |
    wait_for_containers() {
      required_containers=("caddy" "livekit" "egress" "ingress")
      all_up=false

      echo "Waiting for containers to start..."

      for attempt in {1..30}; do
        # Check how many containers are up
        up_containers=$(docker ps --format '{{.Names}}')

        all_up=true
        for container in caddy livekit egress ingress; do
          if [[ ! "$up_containers" =~ $container ]]; then
            all_up=false
            break
          fi
        done

        if [ "$all_up" = true ]; then
          echo "All containers are up."
          break
        else
          echo "Waiting for all containers to come up (attempt $attempt)..."
          sleep 10
        fi
      done

      if [ "$all_up" = false ]; then
        echo "Timeout: Not all containers are up after waiting."
        exit 1
      fi
    }
  # Wait for the containers to start
  - wait_for_containers

  # Set up log symlinks for CloudWatch agent
  - ln -sf /var/lib/docker/containers/$(docker ps -aqf "name=livekit" --no-trunc)/*-json.log /var/log/livekit/livekit.log
  - ln -sf /var/lib/docker/containers/$(docker ps -aqf "name=caddy" --no-trunc)/*-json.log /var/log/caddy/caddy.log
  - ln -sf /var/lib/docker/containers/$(docker ps -aqf "name=egress" --no-trunc)/*-json.log /var/log/livekit/egress.log
  - ln -sf /var/lib/docker/containers/$(docker ps -aqf "name=ingress" --no-trunc)/*-json.log /var/log/livekit/ingress.log
  # Restart CloudWatch agent to pick up new log files
  - systemctl restart amazon-cloudwatch-agent
  - echo "INITIATE CLOUD WATCH PROCESS"

