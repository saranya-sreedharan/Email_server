#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root!${NC}"
    exit 1
fi

# Check if domain name is provided
#example mail.mnsp.co.in

if [ $# -ne 1 ]; then
    echo -e "${RED}Usage: $0 <DOMAIN_NAME>${NC}"
    exit 1
fi

DOMAIN_NAME=$1

# Update and upgrade the system
echo -e "${YELLOW}Updating and upgrading the system...${NC}"
if ! apt update && apt upgrade -y; then
    echo -e "${RED}Failed to update and upgrade the system!${NC}"
    exit 1
fi
echo -e "${GREEN}System updated and upgraded successfully!${NC}"

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
if ! apt install -y docker.io; then
    echo -e "${RED}Failed to install Docker!${NC}"
    exit 1
fi
echo -e "${GREEN}Docker installed successfully!${NC}"

# Install Docker Compose
echo -e "${YELLOW}Installing Docker Compose...${NC}"
if ! apt install -y docker-compose; then
    echo -e "${RED}Failed to install Docker Compose!${NC}"
    exit 1
fi
echo -e "${GREEN}Docker Compose installed successfully!${NC}"

# Download Docker Compose binary
echo -e "${YELLOW}Downloading Docker Compose binary...${NC}"
if ! curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
    echo -e "${RED}Failed to download Docker Compose binary!${NC}"
    exit 1
fi

# Apply executable permissions to the Docker Compose binary
echo -e "${YELLOW}Applying executable permissions to Docker Compose binary...${NC}"
if ! chmod +x /usr/local/bin/docker-compose; then
    echo -e "${RED}Failed to apply executable permissions to Docker Compose binary!${NC}"
    exit 1
fi
echo -e "${GREEN}Docker Compose binary downloaded and permissions applied successfully!${NC}"

# Clone the mailcow repository
echo -e "${YELLOW}Cloning the mailcow repository...${NC}"
if ! git clone https://github.com/mailcow/mailcow-dockerized; then
    echo -e "${RED}Failed to clone the mailcow repository!${NC}"
    exit 1
fi
echo -e "${GREEN}mailcow repository cloned successfully!${NC}"

# Change to the mailcow directory
cd mailcow-dockerized || { echo -e "${RED}Failed to change directory to mailcow-dockerized!${NC}"; exit 1; }

# Generate the configuration
echo -e "${YELLOW}Generating the mailcow configuration...${NC}"
if ! echo "$DOMAIN_NAME" | ./generate_config.sh; then
    echo -e "${RED}Failed to generate the mailcow configuration!${NC}"
    exit 1
fi
echo -e "${GREEN}Mailcow configuration generated successfully!${NC}"

# Start mailcow services
echo -e "${YELLOW}Starting mailcow services...${NC}"
if ! docker-compose up -d; then
    echo -e "${RED}Failed to start mailcow services!${NC}"
    exit 1
fi
echo -e "${GREEN}Mailcow services started successfully!${NC}"

# Display server information
PUBLIC_IP=$(curl -s ifconfig.me)
echo -e "${GREEN}Mail server is available at http://$PUBLIC_IP${NC}"
echo -e "${GREEN}Username: admin${NC}"
echo -e "${GREEN}Password: moohoo${NC}"
