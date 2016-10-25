#!/bin/bash
echo 'deb http://www.ubnt.com/downloads/unifi/debian stable ubiquiti' | sudo tee -a /etc/apt/sources.list.d/100-ubnt.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50 && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
sudo apt-get update
sudo apt-get install unifi -y
echo "echo \"\"" >> /etc/profile
echo "echo \"██▀███  ▓█████ ▓█████▄ ▓█████  ██▓███   ██▓     ▒█████  ▓██   ██▓\"" >> /etc/profile
echo "echo \"▓██ ▒ ██▒▓█   ▀ ▒██▀ ██▌▓█   ▀ ▓██░  ██▒▓██▒    ▒██▒  ██▒ ▒██  ██▒\"" >> /etc/profile
echo "echo \"▓██ ░▄█ ▒▒███   ░██   █▌▒███   ▓██░ ██▓▒▒██░    ▒██░  ██▒  ▒██ ██░\"" >> /etc/profile
echo "echo \"▒██▀▀█▄  ▒▓█  ▄ ░▓█▄   ▌▒▓█  ▄ ▒██▄█▓▒ ▒▒██░    ▒██   ██░  ░ ▐██▓░\"" >> /etc/profile
echo "echo \"░██▓ ▒██▒░▒████▒░▒████▓ ░▒████▒▒██▒ ░  ░░██████▒░ ████▓▒░  ░ ██▒▓░\"" >> /etc/profile
echo "echo \"░ ▒▓ ░▒▓░░░ ▒░ ░ ▒▒▓  ▒ ░░ ▒░ ░▒▓▒░ ░  ░░ ▒░▓  ░░ ▒░▒░▒░    ██▒▒▒\"" >> /etc/profile
echo "echo \" ░▒ ░ ▒░ ░ ░  ░ ░ ▒  ▒  ░ ░  ░░▒ ░     ░ ░ ▒  ░  ░ ▒ ▒░  ▓██ ░▒░\"" >> /etc/profile
echo "echo \" ░░   ░    ░    ░ ░  ░    ░   ░░         ░ ░   ░ ░ ░ ▒   ▒ ▒ ░░\"" >> /etc/profile
echo "echo \"  ░        ░  ░   ░       ░  ░             ░  ░    ░ ░   ░ ░\"" >> /etc/profile
echo "echo \"                ░                                        ░ ░\"" >> /etc/profile
echo "echo \"                                                   redeploy.se\"" >> /etc/profile
echo "echo \"\"" >> /etc/profile
echo "echo \"Your management URL for your Unifi Controller is https://\`curl -s ipecho.net/plain; echo\`:8443\"" >> /etc/profile
echo "echo \"\"" >> /etc/profile
