#!/bin/sh

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "\n${BOLD}=============================================${NC}"
echo -e "${BOLD}       FastAPI Project - Ready to Use!         ${NC}"
echo -e "${BOLD}=============================================${NC}"

echo -e "\n${BOLD}Prestart Details:${NC}"
echo -e "${GREEN}✅ Database initialization and migrations completed successfully.${NC}"

echo -e "\n${BOLD}Application URLs:${NC}"
echo -e "${BLUE}Frontend Dashboard:${NC} http://dashboard.localhost"
echo -e "${BLUE}API Documentation:${NC}  http://api.localhost/docs"
echo -e "${BLUE}Database Admin:${NC}     http://adminer.localhost"
echo -e "${BLUE}Mail Catcher:${NC}       http://mail.localhost"
echo -e "${BLUE}Traefik Dashboard:${NC}  http://traefik.localhost or http://localhost:8081"

echo -e "\n${BOLD}Default Login:${NC}"
echo -e "${BLUE}Email:${NC}    admin@example.com"
echo -e "${BLUE}Password:${NC} FastAPI_Secure_2025!"
echo -e "${BOLD}=============================================${NC}\n"
