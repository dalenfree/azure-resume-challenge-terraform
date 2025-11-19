# azure-resume-challenge-terraform

After completing the challenge with Bicep, I decided to try it again with Terraform instead. I found the overall experience of using both to be pretty similar, but if I had to choose one IaC platform moving forward it will probably be Terraform, mainly because it can be used with multiple cloud providers and seems to be more widely used.

## Here are some steps you can follow to use the template above to see a finished product

1. Customize variables in `IaC/variables.tf` to your needs so the variables point to appropriate values (IMPORTANT: if you revise the Cosmos DB database and container IDs, remember to update them in `backend/function_app.py` as well!);

2. Terraform Apply from `IaC` folder;
  
```
cd path/to/azure-resume-challenge-terraform/IaC
terraform validate
terraform apply
```

3. If you haven't already, create GitHub repo. I do this on the website, but you can choose to do it via CLI.

4. Create/setup Service Principal for GitHub (in order for workflows to work);

Log into Azure CLI
```
az login
```

Create a Service Principal you will use for GitHub
```
az ad sp create-for-rbac --name <example-oidc-name> --role contributor --scopes /subscriptions/<subscription-id>
```

The output will look like this:
```
{
  "appId": "`x11xx111-x11x-111x-1111-x1111x11x111`", <- this is `AZURE_CLIENT_ID`
  "displayName": "`example-display-name`",
  "password": "`xxxxxx.xxxxxxxxxxxxxxxxxxxx`",
  "tenant": "`1xxx11x1-x11x-11xx-xx11-x111xx111111`"  <- this is `AZURE_TENANT_ID`
  } 
```
Assign "create" role to the Service Principal
``` 
az role assignment create \
--assignee ``AZURE_CLIENT_ID` \
--role Contributor \
--scope /subscriptions/`AZURE_SUBSCRIPTION_ID`
```

Add federated credentials to the Service Principal
```
az ad app federated-credential create \
--id `AZURE_CLIENT_ID` \
--parameters '{
    "name": "github-actions-oidc",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:`username/repo`:ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch deployments",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```
5. Add secrets from GitHub service principal to GitHub Repo secrets
 ``` 
  AZURE_CLIENT_ID
  AZURE_SUBSCRIPTION_ID
  AZURE_TENANT_ID
  RESOURCE_GROUP_NAME
  FUNCTIONAPP_NAME <- Get by using `az functionapp list --resource-group <RESOURCE_GROUP_NAME>`
  ACCOUNT_NAME
  FRONTDOOR
  FRONTDOOR_ENDPOINT
  COSMOS_DB_ENDPOINT
  COSMOS_DB_KEY
  COSMOS_DB_DATABASE_NAME
  COSMOS_DB_CONTAINER_NAME
```
6. Push to GitHub
```
cd folder/containing/azure-resume-challenge-terraform
git add -A
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/<username>/<repo-name>
git push -u origin main
```

7. Run Frontend and Backend workflows. This should be automatic - if not, then log into GitHub from a browser and run the workflows.

After deploy:
1. Fetch name of SQL server and database for sql_upload_script.py

`your_database`
```
az cosmosdb sql database list --resource-group your_resource_group_name --account-name your_cosmos_account_name --query "[].name" --output table

```

`your_container`
```
az cosmosdb sql container list --resource-group your_resource_group_name --account-name your_cosmos_account_name --database-name your_database_name --query "[].name" --output table

```

2. Set up DNS with Front Door (CNAME, TXT)
I created a script for the CNAME and TXT Secret records in the 

3. Profit!

## Learnings

- GitHub worflow ymls are sensitive to folder structures and *look for zip files in the root directory by default*.

- SQL JSON files must have an `id` field in order to be valid.

- Adding secrets and variables means that you need to make sure the variables are properly used in all files.