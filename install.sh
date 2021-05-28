#!/usr/bin/env bash
# Provisions Jenkins

VIRTUAL_HOST=${VIRTUAL_HOST:-localhost}

# Clean up.
docker-compose rm -s -f
rm -rf jenkins_home

# Copy jobs definition.
cp -r jenkins_template jenkins_home
chmod +x jenkins_home/install_plugins.sh
sed -i "s/localhost/${VIRTUAL_HOST}/" jenkins_home/nodes/Worker/config.xml

# Get the NGINX, Jenkins and Puppeteer up.
docker-compose up -d

# Install Jenkins plugins.
docker-compose exec jenkins bash -c "~/install_plugins.sh"

# Guide users with the following configuration.
echo ''
echo "###################################################################"
echo "# Use this password to proceed with the configuration:            #"
PASSWORD=$(cat jenkins_home/secrets/initialAdminPassword)
echo "#      ${PASSWORD}"
echo "###################################################################"

