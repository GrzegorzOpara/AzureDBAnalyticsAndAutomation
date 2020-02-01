# Import-Module Az

# connect to Azure
Connect-AzAccount

# define the resource group name
$resourceGroup = 'DevOpsCaveRG'
$storageAccountName = 'devopscavesa90211'
$containerName = 'bacpac'
$sqlDbName1 = 'devopscave-sql-lowusage-06'
$sqlDbName2 = 'devopscave-sql-highusage-06'
$LocalBacPacPath = 'C:\temp\stackoverflow2010.bacpac'

New-AzResourceGroup -Name $resourceGroup -Location 'West Europe'

New-AzResourceGroupDeployment -Name StorageAccountDeploy `
-ResourceGroupName $resourceGroup `
-Mode Incremental `
-TemplateFile .\Infrastructure\StorageAccount\azuredeploy.json `
-TemplateParameterFile .\Infrastructure\StorageAccount\azuredeploy.parameters.json `
-storageAccountName $storageAccountName `
-containerName $containerName

New-AzResourceGroupDeployment -Name SqlServerDeploy `
-ResourceGroupName $resourceGroup `
-Mode Incremental `
-TemplateFile .\Infrastructure\LogicalSqlServer\azuredeploy.json `
-TemplateParameterFile .\Infrastructure\LogicalSqlServer\azuredeploy.parameters.json

New-AzResourceGroupDeployment -Name LogAnalyticsWorkspaceDeploy `
-ResourceGroupName $resourceGroup `
-Mode Incremental `
-TemplateFile .\Infrastructure\LogAnalytics\azuredeploy.json `
-TemplateParameterFile .\Infrastructure\LogAnalytics\azuredeploy.parameters.json

New-AzResourceGroupDeployment -Name ElasticPoolDeploy `
-ResourceGroupName $resourceGroup `
-Mode Incremental `
-TemplateFile .\Infrastructure\ElasticPool\azuredeploy.json `
-TemplateParameterFile .\Infrastructure\ElasticPool\azuredeploy.parameters.json

# Copy the bacpac file to the storage account
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $storageAccountName).Value[0]
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Set-AzStorageBlobContent -Context $ctx -Container $containerName -File $LocalBacPacPath -Blob (Split-Path $LocalBacPacPath -leaf)
$bacpacUrl = (Get-AzStorageBlob -context $ctx -blob (Split-Path $LocalBacPacPath -leaf) -Container $containerName).ICloudBlob.uri.AbsoluteUri

New-AzResourceGroupDeployment -Name AzureDbDeploy_HighUsage `
-ResourceGroupName $resourceGroup `
-Mode Incremental `
-TemplateFile .\Infrastructure\AzureDB\azuredeploy.json `
-TemplateParameterFile .\Infrastructure\AzureDB\azuredeploy.parameters.json `
-storageAccountKey $storageAccountKey `
-bacpacUrl $bacpacUrl `
-sqlDbName $sqlDbName1

New-AzResourceGroupDeployment -Name AzureDbDeploy_LowUsage `
-ResourceGroupName $resourceGroup `
-Mode Incremental `
-TemplateFile .\Infrastructure\AzureDB\azuredeploy.json `
-TemplateParameterFile .\Infrastructure\AzureDB\azuredeploy.parameters.json `
-storageAccountKey $storageAccountKey `
-bacpacUrl $bacpacUrl `
-sqlDbName $sqlDbName2
