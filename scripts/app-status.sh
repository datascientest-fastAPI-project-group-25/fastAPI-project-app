#!/usr/bin/env bash

# Script to show the status of all services with special handling for prestart
# Usage: ./scripts/app-status.sh

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Header
echo -e "${BOLD}=============================================${NC}"
echo -e "${BOLD}       FastAPI Project Application Status     ${NC}"
echo -e "${BOLD}=============================================${NC}"

# Get all services status
echo -e "\n${BOLD}Services Status:${NC}"
docker compose ps -a --format "table {{.Name}}\t{{.Service}}\t{{.Status}}\t{{.Ports}}" | while read line; do
  if [[ $line == *"prestart"* ]] && [[ $line == *"Exited"* ]]; then
    # Check prestart exit code
    CONTAINER_NAME=$(echo $line | awk '{print $1}')
    EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' $CONTAINER_NAME)
    
    if [ "$EXIT_CODE" -eq 0 ]; then
      # Replace "Exited" with "DONE" for successful prestart
      echo -e "${GREEN}$(echo $line | sed 's/Exited (0).*ago/DONE (Initialization Complete)/')${NC}"
    else
      # Show error for failed prestart
      echo -e "${RED}$(echo $line | sed "s/Exited ($EXIT_CODE).*ago/FAILED (Exit Code: $EXIT_CODE)/")${NC}"
    fi
  elif [[ $line == *"(healthy)"* ]]; then
    # Highlight healthy services
    echo -e "${GREEN}$line${NC}"
  elif [[ $line == *"Exited"* ]]; then
    # Highlight exited services
    echo -e "${RED}$line${NC}"
  elif [[ $line == *"Starting"* ]]; then
    # Highlight starting services
    echo -e "${YELLOW}$line${NC}"
  elif [[ $line == *"NAME"* ]]; then
    # Header line
    echo -e "${BOLD}$line${NC}"
  else
    # Running services
    echo -e "${BLUE}$line${NC}"
  fi
done

# Show additional information for prestart if it exists
PRESTART_CONTAINER="fastapi-project-app-prestart-1"
if docker ps -a --format '{{.Names}}' | grep -q "$PRESTART_CONTAINER"; then
  EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' $PRESTART_CONTAINER)
  
  echo -e "\n${BOLD}Prestart Details:${NC}"
  if [ "$EXIT_CODE" -eq 0 ]; then
    echo -e "${GREEN}✅ Database initialization and migrations completed successfully.${NC}"
  else
    echo -e "${RED}❌ Database initialization failed with exit code $EXIT_CODE.${NC}"
    echo -e "${RED}   Check logs with: docker compose logs prestart${NC}"
  fi
fi

echo -e "\n${BOLD}=============================================${NC}"
echo -e "${BOLD}Application URLs:${NC}"
echo -e "Frontend Dashboard: ${BLUE}http://dashboard.localhost${NC}"
echo -e "API Documentation:  ${BLUE}http://api.localhost/docs${NC}"
echo -e "Database Admin:     ${BLUE}http://adminer.localhost${NC}"
echo -e "Mail Catcher:       ${BLUE}http://mail.localhost${NC}"
echo -e "Traefik Dashboard:   ${BLUE}http://traefik.localhost${NC} or ${BLUE}http://localhost:8081${NC}"
echo -e "${BOLD}=============================================${NC}"

# Login information
echo -e "\n${BOLD}Default Login:${NC}"
echo -e "Email:    ${BLUE}admin@example.com${NC}"
echo -e "Password: ${BLUE}FastAPI_Secure_2025!${NC}"
echo -e "${BOLD}=============================================${NC}"
