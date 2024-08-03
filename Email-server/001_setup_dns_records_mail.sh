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

# Check if parameters are provided
if [ $# -ne 2 ]; then
    echo -e "${RED}Usage: $0 <DNS_SERVER_IP> <MAIL_SERVER_IP>${NC}"
    exit 1
fi

DNS_SERVER_IP=$1
MAIL_SERVER_IP=$2

DNS_ZONE_FILE="/etc/bind/zones/db.mnsp.co.in"

# Backup the existing DNS zone file
echo -e "${YELLOW}Backing up the existing DNS zone file...${NC}"
if ! cp $DNS_ZONE_FILE ${DNS_ZONE_FILE}.bak; then
    echo -e "${RED}Failed to backup the DNS zone file!${NC}"
    exit 1
fi
echo -e "${GREEN}DNS zone file backed up successfully!${NC}"

# Update the DNS zone file
echo -e "${YELLOW}Updating the DNS zone file...${NC}"
cat > $DNS_ZONE_FILE <<EOL
\$TTL 604800
@   IN  SOA ns1.mnsp.co.in. admin.mnsp.co.in. (
              1     ; Serial
         604800     ; Refresh
          86400     ; Retry
        2419200     ; Expire
         604800 )   ; Negative Cache TTL


; Name servers
@       IN  NS      ns1.mnsp.co.in.
@       IN  NS      ns2.mnsp.co.in.


; A records for name servers
ns1     IN  A       $DNS_SERVER_IP
ns2     IN  A       $DNS_SERVER_IP


; A record for the domain
@       IN  A       $DNS_SERVER_IP


; Other records
mail     IN  A       $MAIL_SERVER_IP
www     IN  A       $DNS_SERVER_IP


; MX record
@       IN  MX      10  mail.mnsp.co.in.


; SPF record
@       IN  TXT     "v=spf1 mx ~all"


; CNAME records
autodiscover   600  IN  CNAME   mail.mnsp.co.in.
autoconfig     600  IN  CNAME   mail.mnsp.co.in.


; DMARC record
_dmarc  IN  TXT     "v=DMARC1; p=none; rua=mailto:postmaster@mnsp.co.in"


; Additional DMARC record
_DMARC   IN  TXT     "v=DMARC1; p=none; rua=mailto:92de9420@mxtoolbox.dmarc-report.com; ruf=mailto:92de9420@forensics.dmarc-report.com; fo=1"


; DKIM record
dkim._domainkey     IN  TXT     "v=DKIM1; t=s; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCdElxkH0qyJQxKxjWy+/coFrVXPOmKQQQB6eMLkM8Nq+/ypnaddbfBr3uz/2lBjztPg1kojr/8x/h4q4HZSbHT1Ko4bINvqD2qMCxeamZxQrKXbw8p7rFCBo8fHI5KZzWhFdj6DvfG9lwsalB33Kq17hiPyYKlBG27SPy5i3P94QIDAQAB"
EOL

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update the DNS zone file!${NC}"
    exit 1
fi
echo -e "${GREEN}DNS zone file updated successfully!${NC}"

# Restart BIND9 to apply changes
echo -e "${YELLOW}Restarting BIND9 service...${NC}"
if ! systemctl restart bind9; then
    echo -e "${RED}Failed to restart BIND9 service!${NC}"
    exit 1
fi
echo -e "${GREEN}BIND9 service restarted successfully!${NC}"

echo -e "${GREEN}DNS records updated successfully!${NC}"
