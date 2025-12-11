# AzureConsumptionFabric
This project provides an end-to-end solution to monitor Azure consumption for a client using Microsoft Fabric. It enables proactive detection of anomalies and supports informed decision-making to optimize costs.

## High level architecture 

![diagramaSolucion](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/diagramaSolucionFabric.png) 

### Architecture details :

#### Data Source:

Azure Cost Management API as the primary source of consumption data.

#### Data Ingestion:

A Fabric notebook extracts data from the API and loads it into a Lakehouse.

#### Data Transformation:

Data is copied from the Lakehouse to a Warehouse table.
Stored procedures populate aggregated tables for reporting.

#### Visualization:

A Power BI dashboard connects to aggregated tables to display consumption metrics, trends, and anomalies.


## Requirements

Permissions 
1. User with Global Administrator Role in Azure ( It will be required for configure the EnrollmentReader role in the service principal)
2. Azure subscription and a resource group with permission to create resources
3. Fabric workspace with contributor role

Software required for the deployment : 
1. [PowerBI Desktop](https://www.microsoft.com/en-us/download/details.aspx?id=58494)

Create a new Fabric Capacity (ignore this step if you already have one)
1. Go to the Azure Portal and create a new [Fabric capacity](https://learn.microsoft.com/en-us/fabric/enterprise/buy-subscription#buy-an-azure-sku) in your previously defined resource group.

Create a new [workspace](https://learn.microsoft.com/en-us/fabric/fundamentals/create-workspaces) in Fabric, make sure to use your previoly created capacity and create the following Fabric items:
1. [Lakehouse](https://learn.microsoft.com/en-us/fabric/data-engineering/tutorial-build-lakehouse). Don't enable lakehouse schemas
2. [Warehouse](https://learn.microsoft.com/en-us/fabric/data-warehouse/create-warehouse).
3. [Pipeline](https://learn.microsoft.com/en-us/fabric/data-factory/create-first-pipeline-with-sample-data#create-a-pipeline). Empty pipeline
4. [Environment](https://learn.microsoft.com/en-us/fabric/data-engineering/create-and-use-environment). Runtime 1.3 with spark 3.5


## Setup Guide

### Getting permission to authenticate with the Cost management API

1. Create a service principal
   - Save the following values : application ID , tenantID and secret value 
2. Asign Enrollment reader role to the Service Principal : 
   - For Customers with Enterprise Agreements (EA) please follow this guide : https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/assign-roles-azure-service-principals
   - For customers with Microsoft Agreements please follow this guide : https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/understand-mca-roles#manage-billing-roles-in-the-azure-portal
  

## Import ingestion notebook and get advisor notebook

1. Inside the ingestionNotebook folder you will find the following files: ingestionNotebook.ipynb and get_advisor_data.ipynb, please download both files to your computer.
2. Go to your Fabric Workspace and click on import -> notebook -> from your computer  ![Import notebook](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/importNotebook.png)
3. Once the notebook is imported, go to data sources and add new data item, make sure to select the lakehouse previously created. ![Add data source](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/addnewdatasource.png)
4. Delete any data source not used.
5. Select the environment previously created.
6. Repeat the process for both notebooks.

## Warehouse objects
Inside the Warehouse folder you will find the following files :
1. consumption_tables.sql -> Tables required
2. delete_current_period.sql -> Stored procedure that delete data from the current processed period
3. cost_processing.sql -> Stored procedure that process aggregated tables used by the report

Go to your warehouse item , add a new query and execute the content of both files.


## Pipeline configuration
![ADF Pipeline](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/pipeline.png)

Now we are going to import the pipeline will orchestrate the complete data flow between the Azure Consumption API and the Fabric items

1. Download the pipeline template to your computer from pipelineTemplate/costMasterPipeline.zip.
2. Go to your pipeline item 
3. Import the template into ADF Piplines
4. ![Import pipeline](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/importPipelineTemplate.png)
5. Configure the linked services for the warehouse element
6. Change the settings of both notebooks with your workspace and select the appropiate notebook
7. ![Notebook settings](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/notebookSettings.png)

### Pipeline parameters

Configure the following parameters  : 
1. billing_account_id -> BillID or enrollment number
2. tenant_id -> Tenant ID ( obtained from service principal creation )
3. client_id -> Application ID of the service principal ( obtained from service principal creation )
4. client_secret -> Secret of the service principal
5. Period -> Period of time that will be processed by the pipeline, 0 : means current month, -1 : past month, -2 : 2 months ago, and so on..
6. customer_name -> Name of your company (it will be used in file names)
7. lakehouse_cost_table -> Name of the staging cost table
8. lakehouse_log_table -> Name of the log table
9. warehouse_name -> Name of your warehouse object
10. warehouse_schema -> Schema of the warehouse used, by default is 'cost'
11. warehouse_cost_table -> Main table of the warehouse, by default is 'consumoAzure'

   ![ADF Pipeline](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/parametersPipeline.png)

## Schedule the daily execution of the pipeline using triggers

1. Select schedule
   ![New trigger](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/newschedule.png)
2. Configure the daily schedule execution :
   ![Trigger wizard](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/dailytrigger.png)

## Schedule a monthly execution of the pipeline using triggers
We recommend to configure a monthly execution that will process previous months, this is because it could be ajustments at the begining of each month. A recommended day would be to execute it each day 5 of month.

1.Duplicate your pipeline object 
2. Change the period parameter to -1
3. Select schedule
   ![New trigger](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/newschedule.png)
4. Configure the  monthly schedule execution :
   ![Trigger wizard](https://github.com/jugordon/AzureConsumptionFabric/blob/main/resources/pipelineMonthlyExecution.png)

   
## Connect and publish PowerBI report
1. Download the PowerBI template in PowerBITemplate/Azure_Consumption.pbix
2. Open the file in PowerBI Desktop
3. Cancel any attempt of authentication to the data source
4. Go to transform data
   ![Trigger wizard](https://github.com/jugordon/AzureConsumption/blob/main/resources/powerbitransform.png)
5. Configure the source for each of the tables
   ![Trigger wizard](https://github.com/jugordon/AzureConsumption/blob/main/resources/powerbiconfiguresource.png)
6. Change the server endpoint, use the SQL endpoint of your warehouse
   ![Trigger wizard](https://github.com/jugordon/AzureConsumption/blob/main/resources/powerbiconfigureServer.png)
7. After you see that your PowerBI data shows your data, click on Publish and select the workspace.
8. 

## Data Agent -- pending
