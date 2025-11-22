import requests
import json
import os

# -------------------------------------------
# export API_KEY="your_api_key"
# export SECRET_API_KEY="your_secret_api_key"
# export RECORD_NAME="subdomain"
# export DNS_DOMAIN="yourdomain.com"
# -------------------------------------------

API_KEY = os.getenv("API_KEY")
SECRET_API_KEY = os.getenv("SECRET_API_KEY")
DOMAIN = os.getenv("DNS_DOMAIN")   # replace with your domain

# DNS record values
record_name = os.getenv("RECORD_NAME")  # subdomain for the DNS record
record_type = "CNAME"   # DNS record type
record_content = os.getenv("FRONTDOOR_ENDPOINT")  # replace with your Front Door endpoint
record_ttl = "600"
record_notes = "Cloud Resume Challenge, Terraform"

# -------------------------------------------
# Build URL
# -------------------------------------------
url = f"https://api.porkbun.com/api/json/v3/dns/create/{DOMAIN}"

# -------------------------------------------
# Build JSON payload
# -------------------------------------------
payload = {
    "apikey": API_KEY,
    "secretapikey": SECRET_API_KEY,
    "name": record_name,
    "type": record_type,
    "content": record_content,
    "ttl": record_ttl
}

# -------------------------------------------
# Send POST request
# -------------------------------------------
response = requests.post(url, json=payload)

# -------------------------------------------
# Print results
# -------------------------------------------
if response.status_code == 200:
    print("API Response:")
    print(json.dumps(response.json(), indent=2))
else:
    print("Error:", response.status_code)
    print(response.text)