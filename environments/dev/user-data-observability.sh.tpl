#!/bin/bash
set -euo pipefail

AWS_REGION="${aws_region}"
AMP_WORKSPACE_ID="${amp_workspace_id}"
LOG_GROUP_NAME="${cloudwatch_log_group_name}"
ECR_REPOSITORY_URL="${ecr_repository_url}"
SSM_PARAMETER_NAME="${ssm_parameter_name}"

# Install core tools
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y curl wget gnupg unzip ca-certificates
else
  yum install -y curl wget gnupg2 unzip ca-certificates
fi

# Install node_exporter
NODE_EXPORTER_VERSION="1.7.0"
cd /tmp
curl -L -o node_exporter.tar.gz https://github.com/prometheus/node_exporter/releases/download/v${"$"}{NODE_EXPORTER_VERSION}/node_exporter-${"$"}{NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
mkdir -p /opt/node_exporter
tar xzf node_exporter.tar.gz -C /opt/node_exporter --strip-components=1
install -m 0755 /opt/node_exporter/node_exporter /usr/local/bin/node_exporter
cat >/etc/systemd/system/node_exporter.service <<'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/node_exporter --web.listen-address=":9100"
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now node_exporter

# Install AWS Distro for OpenTelemetry Collector
OTEL_VERSION="0.75.0"
cd /tmp
curl -L -o aws-otel-collector.tar.gz https://github.com/aws-observability/aws-otel-collector/releases/download/v${"$"}{OTEL_VERSION}/aws-otel-collector-${"$"}{OTEL_VERSION}-linux-amd64.tar.gz
mkdir -p /tmp/aws-otel
tar xzf aws-otel-collector.tar.gz -C /tmp/aws-otel
install -m 0755 /tmp/aws-otel/aws-otel-collector /usr/local/bin/aws-otel-collector
cat >/etc/otel-collector-config.yaml <<'EOF'
receivers:
  hostmetrics:
    collection_interval: 60s
    scrapers: [cpu, filesystem, memory, network]
  prometheus:
    config:
      scrape_configs:
        - job_name: 'node'
          static_configs:
            - targets: ['localhost:9100']

exporters:
  awsprometheusremotewrite:
    endpoint: "https://aps-workspaces.${"$"}{AWS_REGION}.amazonaws.com/workspaces/${"$"}{AMP_WORKSPACE_ID}/api/v1/remote_write"
    region: "${"$"}{AWS_REGION}"

processors:
  batch: {}

service:
  pipelines:
    metrics:
      receivers: [hostmetrics, prometheus]
      exporters: [awsprometheusremotewrite]
EOF

cat >/etc/systemd/system/aws-otel-collector.service <<'EOF'
[Unit]
Description=AWS Distro for OpenTelemetry Collector
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/aws-otel-collector --config /etc/otel-collector-config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now aws-otel-collector

# Install and configure the CloudWatch agent for centralized log collection
cd /tmp
if command -v apt-get >/dev/null 2>&1; then
  curl -L -o amazon-cloudwatch-agent.deb https://amazoncloudwatch-agent-${"$"}{AWS_REGION}.s3.${"$"}{AWS_REGION}.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  dpkg -i -E amazon-cloudwatch-agent.deb
else
  curl -L -o amazon-cloudwatch-agent.rpm https://amazoncloudwatch-agent-${"$"}{AWS_REGION}.s3.${"$"}{AWS_REGION}.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
  rpm -U amazon-cloudwatch-agent.rpm
fi
mkdir -p /var/log/app
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {"file_path": "/var/log/syslog", "log_group_name": "${"$"}{LOG_GROUP_NAME}", "log_stream_name": "{instance_id}/syslog"},
          {"file_path": "/var/log/messages", "log_group_name": "${"$"}{LOG_GROUP_NAME}", "log_stream_name": "{instance_id}/messages"},
          {"file_path": "/var/log/app/*.log", "log_group_name": "${"$"}{LOG_GROUP_NAME}", "log_stream_name": "{instance_id}/app"}
        ]
      }
    }
  }
}
EOF
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Install the application runtime and start the image selected by Jenkins in SSM.
if command -v apt-get >/dev/null 2>&1; then
  apt-get install -y docker.io awscli
else
  yum install -y docker awscli2 || yum install -y docker awscli
fi
systemctl enable --now docker

APP_VERSION="$(aws ssm get-parameter --name "$${SSM_PARAMETER_NAME}" --query Parameter.Value --output text)"
aws ecr get-login-password --region "$${AWS_REGION}" | docker login --username AWS --password-stdin "$${ECR_REPOSITORY_URL}"
docker pull "$${ECR_REPOSITORY_URL}:$${APP_VERSION}"

cat >/etc/systemd/system/app.service <<EOF
[Unit]
Description=Application container
After=docker.service
Requires=docker.service

[Service]
ExecStartPre=-/usr/bin/docker rm -f ${"${container_name}"}
ExecStart=/usr/bin/docker run --name ${"${container_name}"} --restart unless-stopped -p ${"${container_port}"}:${"${container_port}"} ${"${ecr_repository_url}"}:$${APP_VERSION}
ExecStop=/usr/bin/docker stop -t 30 ${"${container_name}"}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now app.service

# Mark completion
touch /var/log/observability-bootstrap-complete
