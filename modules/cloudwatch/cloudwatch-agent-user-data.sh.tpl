#!/bin/bash
set -euo pipefail

AWS_REGION="${aws_region}"
LOG_GROUP_NAME="${log_group_name}"
ECR_REPOSITORY_URL="${ecr_repository_url}"
SSM_PARAMETER_NAME="${ssm_parameter_name}"

apt-get update -y 2>/dev/null || true
if command -v apt-get >/dev/null 2>&1; then
  apt-get install -y curl ca-certificates
  curl -L -o /tmp/amazon-cloudwatch-agent.deb "https://amazoncloudwatch-agent-$${AWS_REGION}.s3.$${AWS_REGION}.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb"
  dpkg -i -E /tmp/amazon-cloudwatch-agent.deb
else
  yum install -y curl
  curl -L -o /tmp/amazon-cloudwatch-agent.rpm "https://amazoncloudwatch-agent-$${AWS_REGION}.s3.$${AWS_REGION}.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
  rpm -U /tmp/amazon-cloudwatch-agent.rpm
fi

mkdir -p /var/log/app
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {"file_path": "/var/log/syslog", "log_group_name": "$${LOG_GROUP_NAME}", "log_stream_name": "{instance_id}/syslog"},
          {"file_path": "/var/log/messages", "log_group_name": "$${LOG_GROUP_NAME}", "log_stream_name": "{instance_id}/messages"},
          {"file_path": "/var/log/app/*.log", "log_group_name": "$${LOG_GROUP_NAME}", "log_stream_name": "{instance_id}/app"}
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
