import requests
import time
import random
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("test_monitoring")

# Base URL for the API
BASE_URL = "http://api.localhost"

# Endpoints to test
ENDPOINTS = [
    "/api/v1/utils/health-check/",
    "/docs",
    "/openapi.json",
]

# HTTP methods to use
METHODS = ["GET", "POST", "PUT", "DELETE"]

def generate_traffic():
    """Generate random traffic to the API endpoints."""
    for _ in range(50):  # Generate 50 requests
        # Select a random endpoint
        endpoint = random.choice(ENDPOINTS)
        
        # Select a random HTTP method (use GET for simplicity)
        method = "GET"
        
        # Make the request
        url = f"{BASE_URL}{endpoint}"
        logger.info(f"Making {method} request to {url}")
        
        try:
            if method == "GET":
                response = requests.get(url)
            elif method == "POST":
                response = requests.post(url)
            elif method == "PUT":
                response = requests.put(url)
            elif method == "DELETE":
                response = requests.delete(url)
            
            logger.info(f"Response status code: {response.status_code}")
            
            # Introduce some errors for testing
            if random.random() < 0.1:  # 10% chance of error
                logger.error(f"Simulated error for {method} request to {url}")
        
        except Exception as e:
            logger.error(f"Error making request to {url}: {str(e)}")
        
        # Sleep for a random time between requests
        time.sleep(random.uniform(0.1, 0.5))

if __name__ == "__main__":
    logger.info("Starting traffic generation")
    generate_traffic()
    logger.info("Traffic generation complete")
