#!/usr/bin/env bash

cd ~
pwd

while [[ ! -f ./secrets/initialAdminPassword ]]
do
  echo -n "."
  sleep 1
done
PASSWORD=$(cat ./secrets/initialAdminPassword)
echo ""

echo $PASSWORD

wget -N http://localhost:8080/jnlpJars/jenkins-cli.jar --waitretry=5 --retry-on-http-error=503 -q
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin build-token-root
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin credentials-binding
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin timestamper
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin parameterized-trigger
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin ssh-slaves
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:${PASSWORD} install-plugin ws-cleanup -restart
