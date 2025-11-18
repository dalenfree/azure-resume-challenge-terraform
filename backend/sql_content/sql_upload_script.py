import os
import json
from azure.cosmos import CosmosClient

# Load configuration from environment variables
cosmos_endpoint = os.getenv('COSMOS_DB_ENDPOINT')  # Your Cosmos DB account endpoint
cosmos_key = os.getenv('COSMOS_DB_KEY')            # Your Cosmos DB account key
database_name = os.getenv('COSMOS_DB_DATABASE_NAME')                # Your database name
container_name = os.getenv('COSMOS_DB_CONTAINER_NAME')             # Your container name

# Initialize the Cosmos client
client = CosmosClient(cosmos_endpoint, cosmos_key)

# Select the database
database = client.get_database_client(database_name)

# Select the container
container = database.get_container_client(container_name)

# Load JSON data from file
with open('data.json') as json_file:
    json_data = json.load(json_file)

# Insert JSON data into the Cosmos DB container
container.upsert_item(json_data)  # Use upsert to add the item or update if it exists
