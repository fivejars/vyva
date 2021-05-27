#!/usr/bin/env bash
# Provisions Jenkins

# Clean up.
docker-compose rm -s -f
rm -rf jenkins_home

# Copy jobs definition.
cp -r jenkins_template jenkins_home
chmod +x jenkins_home/install_plugins.sh

# Get the NGINX, Jenkins and Puppeteer up.
docker-compose up -d

# Install Jenkins plugins.
docker-compose exec jenkins bash -c "~/install_plugins.sh"

# Guide users with the following configuration.
echo "Use this key to proceed with the configuration"
cat jenkins_home/secrets/initialAdminPassword
