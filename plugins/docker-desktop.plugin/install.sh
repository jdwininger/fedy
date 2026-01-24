#!/bin/bash
set -e

# Add Docker CE repo (required for dependencies)
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker Desktop
dnf install -y https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm
