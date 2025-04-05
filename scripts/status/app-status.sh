#!/bin/sh

# Simple script to show app URLs and login info
# Usage: Used by app-status container at end of startup

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Wait for a moment to make sure everything is ready
sleep 2

# Header with URLs
printf "\n\n${BOLD}=============================================\n"
printf "${BOLD}       FastAPI Application Ready!     \n"
printf "${BOLD}=============================================\n"

# Application URLs
printf "\n${BOLD}Application URLs:${NC}\n"
printf "Frontend Dashboard: ${GREEN}http://dashboard.localhost${NC}\n"
printf "API Documentation:  ${GREEN}http://api.localhost/docs${NC}\n"
printf "Database Admin:     ${GREEN}http://adminer.localhost${NC}\n"
printf "Mail Catcher:       ${GREEN}http://mail.localhost${NC}\n"
printf "Traefik Dashboard:  ${GREEN}http://traefik.localhost${NC} or ${GREEN}http://localhost:8081${NC}\n"

# Login information
printf "\n${BOLD}Default Login:${NC}\n"
printf "Email:    ${BLUE}admin@example.com${NC}\n"
printf "Password: ${BLUE}FastAPI_Secure_2025!${NC}\n"
printf "${BOLD}=============================================\n\n"
