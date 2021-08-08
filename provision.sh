#!/bin/bash

# Abort if anything fails
set -e

USER=`whoami`

#-------------------------- Helper functions --------------------------------

# Console colors
red='\033[0;31m'
green='\033[0;32m'
green_bg='\033[1;97;42m'
yellow='\033[1;33m'
NC='\033[0m'

echo-red () { echo -e "${red}$1${NC}"; }
echo-green () { echo -e "${green}$1${NC}"; }
echo-green-bg () { echo -e "${green_bg}$1${NC}"; }
echo-yellow () { echo -e "${yellow}$1${NC}"; }

user_setup() {
    echo ''
    echo-green '########################'
    echo-green '# User setup           #'
    echo-green '########################'
    echo ''
    echo-yellow 'Set the user password'
    adduser vyva --gecos "VYVA,,,"
    usermod -aG sudo vyva

    # Generate Cert
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -N ''
    # Enter passphrase
    mkdir -p /home/vyva/.ssh
    cat ~/.ssh/id_rsa.pub > /home/vyva/.ssh/authorized_keys
    chown -R vyva:vyva /home/vyva/.ssh
}

install_docker() {
    echo ''
    echo-green '########################'
    echo-green '# Docker installation  #'
    echo-green '########################'
    echo ''

    # See https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
    sudo apt-get -qq update
    sudo apt-get -qq -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    echo 'Adding Docker official GPG key...'
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get -qq update
    echo 'Installing docker...'
    sudo apt-get -qq -y install docker-ce docker-ce-cli containerd.io
    echo 'Docker has been installed'

    # Add current user to docker group.
    sudo usermod -aG docker ${USER}

    echo 'Installing docker-compose...'
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo 'Enabling and restarting docker...'
    sudo systemctl enable docker
    sudo systemctl restart docker

    echo ''
}

install_php() {
    echo ''
    echo-green '########################'
    echo-green '# PHP installation     #'
    echo-green '########################'
    echo ''

    echo 'Installing PHP...'
    sudo apt-get -qq -y install software-properties-common
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt-get -qq update
    sudo apt-get -qq -y install php7.4-cli php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath
    php -v
    echo 'PHP 7.4 has been installed'
    echo ''

    echo 'Installing Composer...'
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    sudo mv composer.phar /usr/local/bin/composer
    composer -v
    echo 'Composer has been installed'
    echo ''
}

install_vimeo_cli() {
    echo ''
    echo-green '###################################'
    echo-green '# Vimeo CLI for VYVA installation #'
    echo-green '###################################'
    echo ''

    echo 'Downloading Vimeo CLI for VYVA...'
    git clone https://github.com/fivejars/vimeo-cli.git ~/vimeo-cli
    cp ~/vimeo-cli/config.example.yml ~/vimeo-cli/config.yml
    cd ~/vimeo-cli

    echo 'Installing Vimeo CLI for VYVA...'
    composer install -n

    echo 'Vimeo CLI has been installed'
    echo ''
}

install_vyva() {
    echo ''
    echo-green '##########################################'
    echo-green '# Jenkins, Nginx, Puppeteer installation #'
    echo-green '##########################################'
    echo ''

    echo 'Cloning docker compose project...'
    git clone https://github.com/fivejars/vyva.git ~/vyva

    # Configure domain here.
    echo ''
    echo-green '##########################################'
    echo-green '# Domain, LetsEncrypt configuration      #'
    echo-green '##########################################'
    echo ''
    echo -e -n "${yellow}Enter the domain name this server will accessible at (e.g., vyva.example.com):${NC} "
    read DOMAIN_NAME
    echo -e -n "${yellow}Enter the email for the SSL certificate notifications (e.g., it@domain.tld):${NC} "
    read SSL_EMAIL

    echo ''
    echo 'Configuring domain...'
    touch ~/vyva/.env
    echo '' > ~/vyva/.env
    echo "VIRTUAL_HOST=${DOMAIN_NAME}" >> ~/vyva/.env
    echo "LETSENCRYPT_HOST=${DOMAIN_NAME}" >> ~/vyva/.env
    echo "LETSENCRYPT_EMAIL=${SSL_EMAIL}" >> ~/vyva/.env
    echo ''
    echo 'Check ~/vyva/.env for the configuration'
    echo ''

    echo-green '##########################################'
    echo-green '# Jenkins provisioning                   #'
    echo-green '##########################################'
    cd ~/vyva
    VIRTUAL_HOST=${DOMAIN_NAME} sudo ./install.sh
    echo ''
    echo-yellow  "############################################################"
    echo-yellow  "# Visit Jenkins at https://${DOMAIN_NAME}/"
    echo-yellow  "############################################################"
}

install_java() {
    echo 'Installing Java...'
    sudo apt-get -y install default-jre
    echo 'JRE has been installed'
}

provision() {
    if [ "${USER}" == "root" ]; then
        user_setup
        echo  ''
        echo-yellow  "############################################################################################"
        echo-yellow  "# Switch to the vyva user by running the following command and execute this script:        #"
        echo-yellow  "# once again:                                                                              #"
        echo-yellow  "#   su - vyva                                                                              #"
        echo-yellow  "#   bash <(wget -qO- https://raw.githubusercontent.com/fivejars/vyva/master/provision.sh)  #"
        echo-yellow  "############################################################################################"
    fi

    if [ "${USER}" == "vyva" ]; then
        # Check if the user belongs to group 'docker'
        if id -nG "${USER}" | grep -qw "docker"; then
            # That means docker is already installed
            echo "User ${USER} belongs to the 'docker' group"
            echo ''
            install_java
            install_php
            install_vimeo_cli
            install_vyva
        else
            install_docker
            echo-yellow "###########################################################################################"
            echo-yellow "# Re-login and execute this script once again:                                            #"
            echo-yellow "#  exit                                                                                   #"
            echo-yellow "#  su - vyva                                                                              #"
            echo-yellow "#  bash <(wget -qO- https://raw.githubusercontent.com/fivejars/vyva/master/provision.sh)  #"
            echo-yellow "###########################################################################################"
        fi
    fi
}

provision

#./install.sh
