---
page_type: sample
languages: Shell Script, Bicep, Yaml, Python, Json
products: Github, Azure Devops, Azure, Azure Data Lake Gen2, Azure Data Factory
description: "Code samples showcasing how to leverage DataOps using Azure Data Factory and Azure DevOps
---

This repository contains code samples and artifacts on how to apply DevOps principles to Infra and Data pipelines according to the following diagram.

Session 1 (InfraOps):
Azure DevOps UI:
- Creating project and Repository
- Creating Service Connections
- Creating Variable Groups
- Creating Pipelines

Github Infra Action 
- to create/ modify Azure dev & production environments to build the followong resources
    * Azure Keyvault
    * Azure Storage Account
    * Azure Data Factory
- to associate the Dev data factory with Azure DevOps Repository

Session 2 (DataOps):
- Building a small data pipeline using Azure 
- Triggering ADO Pipelines to deploy changes from ADF Dev to ADF Production Data Pipeline, followed by triggering ADF production pipeline, producing fresh data


A.	Prerequsites in Azure:
	- Existence of Azure Subscription & Resource Groups (Here we have chosen two resource groups one for dev environment and one for prod environment)
	- Portal/ CLI level Admin (Owner) Access to above two environments for creating two service principals, one for dev and one for prod
	 Object ID: 038c3708-2575-4062-a7ff-cc6411a7d470 (for arudra subscription)
	- Create/ Use spn with contributor access to sub & dev rg
	 az ad sp create-for-rbac --name "atnApp" --role contributor \
				--scopes /subscriptions/5ad2142e-80c4-4a77-9ad2-3f2d3da2bf6c/resourceGroups/mdwdops-dat2-dev-rg\
				--sdk-auth
	A1 (Dev SPN):
	{
	  "clientId": "5c99341a-e906-4e2e-9333-4a4fe767f549",
	  "clientSecret": "xQN8Q~HzebseV-3R1NacHzqSku5O3OJeHZhUIcSB",
	  "subscriptionId": "5ad2142e-80c4-4a77-9ad2-3f2d3da2bf6c",
	  "tenantId": "16b3c013-d300-468d-ac64-7eda0820b6d3",
	  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
	  "resourceManagerEndpointUrl": "https://management.azure.com/",
	  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
	  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
	  "galleryEndpointUrl": "https://gallery.azure.com/",
	  "managementEndpointUrl": "https://management.core.windows.net/"
	}

	A2 (Prod SPN):
	{
	  "clientId": "5c99341a-e906-4e2e-9333-4a4fe767f549",
	  "clientSecret": "9.l8Q~MM9DQ_cJKQXP5asbmRw25-cyZAu_S7Hc-h",
	  "subscriptionId": "5ad2142e-80c4-4a77-9ad2-3f2d3da2bf6c",
	  "tenantId": "16b3c013-d300-468d-ac64-7eda0820b6d3",
	  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
	  "resourceManagerEndpointUrl": "https://management.azure.com/",
	  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
	  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
	  "galleryEndpointUrl": "https://gallery.azure.com/",
	  "managementEndpointUrl": "https://management.core.windows.net/"
	}
	
B. Prequisites in GITHUB
	- Go to Settings-Environments
	- Create an environment called "Dev"
	- Define Github spn action secrets as as following
		AZURE_CREDENTIALS		Dev SPN
		AZURE_CLIENT_ID1		5c99341a-e906-4e2e-9333-4a4fe767f549
		AZURE_CLIENT_ID2		038c3708-2575-4062-a7ff-cc6411a7d470
	- Define Dev environment variables as following
		AZURE_SUBSCRIPTION		5ad2142e-80c4-4a77-9ad2-3f2d3da2bf6c (MCAPS-Hybrid-REQ-51347-2023-arudra)
		AZURE_RG				mdwdops-dat2-dev-rg
		AZURE_KEYVAULT			mdwdopskvdevdat2
		DEPLOY_STORAGE			true
		DEPLOY_ADF				true
		AZURE_DATA_FACTORY		atnadfdevdat2
		AZURE_STORAGE_SKU		Standard_LRS
		AZURE_STORAGE_ACCOUNT	mdwdops-strg-dev-dat2
		GIT_ACCOUNT				arudraMS
		GIT_PROJECT				DataOpsWorkshop
		GIT_REPO				DataOpsWorkshop		
		GIT_COLLAB_BRANCH		main
		GIT_FOLDER				ADF2
		GIT_TYPE				GitHub

	- Create an environment called "Prod"
	- Define Github spn action secrets as as following
		AZURE_CREDENTIALS		Prod SPN
		AZURE_CLIENT_ID1		5c99341a-e906-4e2e-9333-4a4fe767f549
		AZURE_CLIENT_ID2		038c3708-2575-4062-a7ff-cc6411a7d470
	- Define Prod environment variables as following
		AZURE_SUBSCRIPTION		5ad2142e-80c4-4a77-9ad2-3f2d3da2bf6c (MCAPS-Hybrid-REQ-51347-2023-arudra)
		AZURE_RG				mdwdops-dat2-prod-rg
		AZURE_KEYVAULT			mdwdopskvproddat2
		DEPLOY_STORAGE			true
		DEPLOY_ADF				true
		AZURE_DATA_FACTORY		atnadfproddat2
		STORAGE_SKU				Standard_LRS
		AZURE_STORAGE_ACCOUNT	mdwdopsstrgproddat2
	
	- Create github action infra workflow to create the above resources for Dev & Prod by calling the following bicep template
	- Create bicep file for creating a)keyvault, b)storage, c)adf in both dev and prood environment and associat dev adf with git parameters
	- Create github actions (yaml) in adf_publish branch of github repo for kicking of build and release pipelines for ADF
	
	
		steps:
        - name: Azure PowerShell script: Stop ADF triggers
		  uses: azure/AzurePowerShell@4
		  azurePowerShellVersion: LatestVersion
          with:
            subscriptionId: ${{ env.AZURE_SUBSCRIPTION_ID }}
			resourceGroupName: ${{ env.AZURE_RESOURCE_GROUP }}
			template: ${{ github.workspace }}/${{ env.AZURE_DEV_DF_NAME }}/deploymentadf.ps1            
            parameters: '-armTemplate ${{ github.workspace }}/${{ env.AZURE_DEV_DF_NAME }}/ARMTemplateForFactory.json -ResourceGroupName ${{ env.AZURE_RESOURCE_GROUP }} -DataFactoryName ${{ env.AZURE_DEV_DF_NAME }} -predeployment true
	
	
		- name: Deploy ARM Template
		  uses: azure/arm-deploy@v1
		  with:
			subscriptionId: ${{ env.AZURE_SUBSCRIPTION_ID }}
			resourceGroupName: ${{ env.AZURE_RESOURCE_GROUP }}
			template: ${{ github.workspace }}/${{ env.AZURE_DEV_DF_NAME }}/ARMTemplateForFactory.json             
			parameters: ${{ github.workspace }}/${{ env.AZURE_DEV_DF_NAME }}/ARMTemplateParametersForFactory.json 
						factoryName=${{ env.AZURE_PRD_DF_NAME }} 
						AzureKeyVault1_properties_typeProperties_baseUrl="https://mdwdopskvproddat2.vault.azure.net/"
						AzureDataLakeStorage1_properties_typeProperties_url="https://mdwdopsstrgproddat2.dfs.core.windows.net/"
						RestService1_properties_typeProperties_url="https://api.spacexdata.com/v3/"

C.	Open Dev Data Factory - Create pipeline, Linked service using secrets, datasets, copy activity
	- Once Dev Data Factory is saved the following things happen
		* The data factory gets saved in the Git Repo Folder of the main branch
	- Once Dev Data Factory is published the following things happen
		* The data factory gets published in adf_publish branch under  
		* The data factory gets unit tested
		* if the unit testing passes, adf code gets moved to production data factory
