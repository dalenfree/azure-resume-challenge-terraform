import logging
import azure.functions as func
import os
import json
from azure.cosmos import CosmosClient, exceptions

# Create the Azure Function App (anonymous access for simplicity)
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Define the HTTP route for GET and POST
@app.route(route="http_trigger", methods=["GET", "POST"])
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing HTTP request for visitor counter...")

    # === 1. Initialize Cosmos DB client ===
    cosmos_url = os.getenv("COSMOS_DB_URL")  
    cosmos_key = os.getenv("COSMOS_DB_KEY")  

    if not cosmos_url or not cosmos_key:
        return func.HttpResponse(
            json.dumps({"error": "Missing Cosmos DB URL or key in environment variables."}),
            status_code=500,
            mimetype="application/json"
        )

    client = CosmosClient(cosmos_url, credential=cosmos_key)

    # === 2. Select database and container ===
    database_name = "Counter"      # your Cosmos DB database name
    container_name = "Visitors"     # your container name

    try:
        database = client.get_database_client(database_name)
        container = database.get_container_client(container_name)
    except exceptions.CosmosResourceNotFoundError:
        return func.HttpResponse(
            json.dumps({"error": "Database or container not found."}),
            status_code=404,
            mimetype="application/json"
        )

    # === 3. Define item id ===
    item_id = "1"   # based on your current NoSQL document { "id": "1", "count": 1 }

    # === 4. Handle GET requests ===
    if req.method == "GET":
        try:
            item = container.read_item(item=item_id, partition_key=item_id)
            count = item.get("count", 0)
            return func.HttpResponse(
                json.dumps({"count": count}),
                mimetype="application/json"
            )
        except exceptions.CosmosResourceNotFoundError:
            return func.HttpResponse(
                json.dumps({"error": "Visitor record not found."}),
                status_code=404,
                mimetype="application/json"
            )

    # === 5. Handle POST requests (increment count) ===
    elif req.method == "POST":
        try:
            item = container.read_item(item=item_id, partition_key=item_id)
            item["count"] = item.get("count", 0) + 1
            container.replace_item(item=item_id, body=item)

            return func.HttpResponse(
                json.dumps({
                    "message": "Visitor count incremented",
                    "new_count": item["count"]
                }),
                mimetype="application/json",
                status_code=200
            )
        except exceptions.CosmosResourceNotFoundError:
            # If the record doesn't exist, create it
            new_item = {
                "id": item_id,
                "count": 1
            }
            container.create_item(body=new_item)
            return func.HttpResponse(
                json.dumps({
                    "message": "Visitor record created",
                    "new_count": 1
                }),
                mimetype="application/json",
                status_code=201
            )

    # === 6. Handle unsupported methods ===
    else:
        return func.HttpResponse(
            json.dumps({"error": "Method not allowed. Use GET or POST."}),
            status_code=405,
            mimetype="application/json"
        )
