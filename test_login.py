#!/usr/bin/env python3
import requests
import sys
import os


def test_login(base_url, username, password):
    """Test login functionality with the provided credentials."""
    print(f"Testing login with credentials: {username} / {password}")
    print(f"Using API URL: {base_url}")

    # Prepare the form data
    form_data = {"username": username, "password": password, "grant_type": "password"}

    # Set the proper content type for form data
    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    try:
        # Make the login request
        response = requests.post(
            f"{base_url}/api/v1/login/access-token",
            data=form_data,
            headers=headers,
            timeout=10,
        )

        # Print response details
        print(f"Status code: {response.status_code}")
        print(f"Response headers: {response.headers}")

        # Try to parse the response as JSON
        try:
            json_response = response.json()
            print(f"Response JSON: {json_response}")

            if "access_token" in json_response:
                print("\n✅ Login successful! Access token received.")
                return True
            else:
                print("\n❌ Login failed: No access token in response.")
                return False
        except ValueError:
            print(f"Response text (not JSON): {response.text}")
            print("\n❌ Login failed: Response is not valid JSON.")
            return False

    except Exception as e:
        print(f"\n❌ Error during login request: {e}")
        return False


if __name__ == "__main__":
    # Default values
    base_url = "http://localhost:8000"
    username = "admin@example.com"
    password = os.environ.get("TEST_PASSWORD", "FastAPI_Secure_2025!")

    # Allow command-line overrides
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
    if len(sys.argv) > 2:
        username = sys.argv[2]
    if len(sys.argv) > 3:
        password = sys.argv[3]

    # Run the test
    success = test_login(base_url, username, password)

    # Exit with appropriate status code
    sys.exit(0 if success else 1)
