#!/bin/bash
sudo su
su apt upgrade -y
su apt update -y
sudo apt install -y nginx
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo apt install npm -y
sudo apt install nodejs -y