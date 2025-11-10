# AzureConsumptionFabric
This project provides an end-to-end solution to monitor Azure consumption for a client using Microsoft Fabric. It enables proactive detection of anomalies and supports informed decision-making to optimize costs.

## High level architecture 

![diagramaSolucion](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/diagramaSolucionFabric.png) 

Architecture

Data Source:

Azure Cost Management API as the primary source of consumption data.


Data Ingestion:

A Fabric notebook extracts data from the API and loads it into a Lakehouse.


Data Transformation:

Data is copied from the Lakehouse to a Warehouse table.
Stored procedures populate aggregated tables for reporting.


Visualization:

A Power BI dashboard connects to aggregated tables to display consumption metrics, trends, and anomalies.


## Requirements

Permissions 
1. User with Global Administrator Role in Azure ( It will be required for configure the EnrollmentReader role in the service principal)
2. Azure subscription and a resource group with permission to create resources

Software required for the deployment : 
1. [PowerBI Desktop](https://www.microsoft.com/en-us/download/details.aspx?id=58494)

In a workspace in Fabric, create the following resources
1. [Lakehouse](https://learn.microsoft.com/en-us/fabric/data-engineering/tutorial-build-lakehouse).
2. [Warehouse](https://learn.microsoft.com/en-us/fabric/data-warehouse/create-warehouse).
3. [Pipeline](https://learn.microsoft.com/en-us/fabric/data-factory/create-first-pipeline-with-sample-data#create-a-pipeline). Empty pipeline
4. [Environment](https://learn.microsoft.com/en-us/fabric/data-engineering/create-and-use-environment).Runtime 1.3 with spark 3.5


## Setup Guide

### Getting permission to authenticate with the Cost management API

1. Create a service principal
   - Save the following values : application ID , tenantID and secret value 
2. Asign Enrollment reader role to the Service Principal : 
   - For Customers with Enterprise Agreements (EA) please follow this guide : https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/assign-roles-azure-service-principals
   - For customers with Microsoft Agreements please follow this guide : https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/understand-mca-roles#manage-billing-roles-in-the-azure-portal
  

## Import ingestion notebook

## Warehouse objects
Inside the Warehouse folder you will find the following files :
1. consumption_tables.sql -> Tables required
2. cost_processing.sql -> Stored procedure 

Go to your warehouse item , add a new query and execute the content of both files.


## Pipeline configuration
![ADF Pipeline](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/importPipelineTemplate.png)

Now we are going to import the pipeline will orchestrate the complete data flow between the Azure Consumption API and the Fabric items

1. Download the pipeline template to your computer from pipelineTemplate/costMasterPipeline.zip.
2. Go to your pipeline item 
3. Import the template into ADF Piplines ![Import pipeline](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/importPipelineTemplate.png)
4. Configure the linked services for the warehouse element

### Pipeline parameters

Configure the following parameters  : 
1. BillID -> BillID or enrollment number
2. TenantID -> Tenant ID ( obtained from service principal creation )
3. ClientID -> Application ID of the service principal ( obtained from service principal creation )
4. Secret -> Secret of the service principal
5. Period -> Period of time that will be processed by the pipeline, 0 : means current month, -1 : past month, -2 : 2 months ago, and so on..
6. Customer -> Name of your company (it will be used in file names)

   ![ADF Pipeline](https://github.com/jugordon/AzureConsumption/blob/main/resources/adfParameters.png)
