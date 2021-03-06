
# Parameters
$resourceGroup = 'devopsriot-rg'
$logAnalyticsWorkspaceName = "devopsriot-sqlworkspace-1"
$automationAccount = 'devopsriot-aa-1'

# Variables
$dataSourceId = (Get-AzResource -Name $logAnalyticsWorkspaceName -ExpandPropertie -ResourceGroupName $resourceGroup).ResourceId
$location = (Get-AzResourceGroup -Name $resourceGroup).Location
$SubscriptionId = (Get-AzContext).Subscription.id

# Finishing the automation account configuration
.\Infrastructure\ServicePrincipal\New-RunAsAccount.ps1 -ResourceGroup $resourceGroup -AutomationAccountName $automationAccount -ApplicationDisplayName $automationAccount -SubscriptionId $SubscriptionId -CreateClassicRunAsAccount $false -SelfSignedCertPlainPassword $true -SelfSignedCertNoOfMonthsUntilExpired 120

# Scaling down the ellastic pool
# Create a webhook for scaling down elastic pool runbook
$Webhook = New-AzAutomationWebhook -Name "WebHook_ScaleDownAzureSqlElasticPool" -IsEnabled $True  -RunbookName "ScaleDownAzureSqlElasticPool" -ResourceGroup $resourceGroup -AutomationAccountName $automationAccount -ExpiryTime "01.01.2030" -Force

# Create the action group
# Create the corresponding webhook receiver linked to runbook webhook
$webhookReceiver = New-AzActionGroupReceiver -Name 'ScaleDownAzureSqlElasticPool_Receiver' -WebhookReceiver -ServiceUri $Webhook.WebhookURI -UseCommonAlertSchema
# Create action group for scaling down elastip pool
$actionGroup = Set-AzActionGroup -Name "ScaleDownAzureSqlElasticPool" -ResourceGroup $resourceGroup -ShortName "ScaleDownEP" -Receiver $webhookReceiver 

# Create the alert rule underlying objects
$source = New-AzScheduledQueryRuleSource -Query "AzureMetrics | where ResourceProvider=='MICROSOFT.SQL' | where ResourceId contains '/ELASTICPOOLS/' | where MetricName == 'dtu_consumption_percent' | summarize AggregatedValue = avg(Average) by Resource, bin(TimeGenerated, 10m)" -DataSourceId $dataSourceId -QueryType "ResultCount"
$schedule = New-AzScheduledQueryRuleSchedule -FrequencyInMinutes 10 -TimeWindowInMinutes 10
$metricTrigger = New-AzScheduledQueryRuleLogMetricTrigger -ThresholdOperator "GreaterThan" -Threshold 0  -MetricTriggerType "Total" -MetricColumn "Resource"
$aznsActionGroup = New-AzScheduledQueryRuleAznsActionGroup -ActionGroup $ActionGroup.Id
$triggerCondition = New-AzScheduledQueryRuleTriggerCondition -ThresholdOperator "LessThan" -Threshold 10 -MetricTrigger $metricTrigger
$alertingAction = New-AzScheduledQueryRuleAlertingAction -AznsAction $aznsActionGroup -Severity "4" -Trigger $triggerCondition

# Create the alert rule
New-AzScheduledQueryRule -Location $location -Action $alertingAction -Enabled $true -Description "ScaleDownAzureSqlElasticPool" -Schedule $schedule -Source $source -Name "ScaleDownAzureSqlElasticPool" -ResourceGroup $resourceGroup


# Scaling up the elastic pool
# Create a webhook for scaling Up elastic pool runbook
$Webhook = New-AzAutomationWebhook -Name "WebHook_ScaleUpAzureSqlElasticPool" -IsEnabled $true  -RunbookName "ScaleUpAzureSqlElasticPool" -ResourceGroup $resourceGroup -AutomationAccountName $automationAccount -ExpiryTime "01.01.2030" -Force

# Create the action group
# Create the corresponding webhook receiver linked to runbook webhook
$webhookReceiver = New-AzActionGroupReceiver -Name 'ScaleUpAzureSqlElasticPool_Receiver' -WebhookReceiver -ServiceUri $Webhook.WebhookURI -UseCommonAlertSchema
# Create action group for scaling Up elastip pool
$actionGroup = Set-AzActionGroup -Name "ScaleUpAzureSqlElasticPool" -ResourceGroup $resourceGroup -ShortName "ScaleUpEP" -Receiver $webhookReceiver

# Create the alert rule underlying objects
$source = New-AzScheduledQueryRuleSource -Query "AzureMetrics | where ResourceProvider=='MICROSOFT.SQL' | where ResourceId contains '/ELASTICPOOLS/' | where MetricName == 'dtu_consumption_percent' | summarize AggregatedValue = avg(Average) by Resource, bin(TimeGenerated, 10m)" -DataSourceId $dataSourceId -QueryType "ResultCount"
$schedule = New-AzScheduledQueryRuleSchedule -FrequencyInMinutes 10 -TimeWindowInMinutes 10
$metricTrigger = New-AzScheduledQueryRuleLogMetricTrigger -ThresholdOperator "GreaterThan" -Threshold 0  -MetricTriggerType "Total" -MetricColumn "Resource"
$aznsActionGroup = New-AzScheduledQueryRuleAznsActionGroup -ActionGroup $ActionGroup.Id
$triggerCondition = New-AzScheduledQueryRuleTriggerCondition -ThresholdOperator "GreaterThan" -Threshold 70 -MetricTrigger $metricTrigger
$alertingAction = New-AzScheduledQueryRuleAlertingAction -AznsAction $aznsActionGroup -Severity "4" -Trigger $triggerCondition

# Create the alert rule
New-AzScheduledQueryRule -Location $location -Action $alertingAction -Enabled $true -Description "ScaleUpAzureSqlElasticPool" -Schedule $schedule -Source $source -Name "ScaleUpAzureSqlElasticPool" -ResourceGroup $resourceGroup
