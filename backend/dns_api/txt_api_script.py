import requests
import json
import os

# -------------------------------------------
# export API_KEY="your_api_key"
# export SECRET_API_KEY="your_secret_api_key"
# export DNS_SUBDOMAIN="_dnsauth.subdomain"
# export DNS_DOMAIN="yourdomain.com"
# export TXT_SECRET="txt"
# -------------------------------------------
API_KEY = os.getenv("API_KEY")
SECRET_API_KEY = os.getenv("SECRET_API_KEY")
SUBDOMAIN = os.getenv("DNS_SUBDOMAIN")
DOMAIN = os.getenv("DNS_DOMAIN")
TXT = os.getenv("TXT_SECRET")

# DNS record values
record_name = f"{SUBDOMAIN}"
record_type = "TXT"   # DNS record type
record_content = TXT 
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