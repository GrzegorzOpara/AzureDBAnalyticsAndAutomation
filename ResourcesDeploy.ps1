Import-Module Az

$ResourceGroup = 'ColdFusionRG'

New-AzureRmResourceGroup -Name 
New-AzResourceGroupDeployment -Name StorageAccountDeploy -ResourceGroupName $ResourceGroup -Mode Incremental -TemplateFile 