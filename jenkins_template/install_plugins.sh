#!/usr/bin/env bash

cd ~

echo ''
echo ''
echo -n "Preparing to install Jenkins plugins."
while [[ ! -f ./secrets/initialAdminPassword ]]
do
  echo -n "."
  sleep 1
done
PASSWORD=$(cat ./secrets/initialAdminPassword)
echo ''

echo "Waiting for Jenkins to initialize..."
wget -N http://localhost:8080/jnlpJars/jenkins-cli.jar --waitretry=5 --retry-on-http-error=503 -q

echo "Installing Jenkins plugins..."
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin build-token-root
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin credentials-binding
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin timestamper
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin parameterized-trigger
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin ssh-slaves
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin ws-cleanup -restart
