[OutputType("PSAzureOperationResponse")]
param
(
    [Parameter (Mandatory=$false)]
    [object] $WebhookData
)
# $ErrorActionPreference = "stop"

Function ScaleElasticPool
{
    Param (
        [String] $ElasticPoolName
    )

    Disable-AzContextAutosave –Scope Process
    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
    $AzureContext = Select-AzSubscription -SubscriptionId $Conn.SubscriptionID

    $basicTierSKU = @(50, 100, 200, 300, 400, 800, 1200, 1600)
    $standardTierSKU = @(50, 100, 200, 300, 400, 800, 1200, 1600,2000,2500,3000)

    $elasticPool = Get-AzResourceGroup | Get-AzSqlServer | Get-AzSqlElasticPool | Get-AzSqlElasticPool -ElasticPoolName $ElasticPoolName
    Write-Output $elasticPool
    $currentDTU = $elasticPool.dtu

    if($elasticPool.Edition -eq 'Basic') {
        $TierSKU = $basicTierSKU
    }
    else {
        $TierSKU = $standardTierSKU
    }

    if([array]::IndexOf($TierSKU,$currentDTU) -gt 0){    
        $position = [array]::IndexOf($TierSKU,$currentDTU)
        $newDTU = $TierSKU[$position - 1]
        Set-AzSqlElasticPool -ResourceGroupName $elasticPool.ResourceGroupName -ServerName $elasticPool.ServerName -ElasticPoolName $elasticPoolName -Dtu $newDTU -DatabaseDtuMax $newDTU -DatabaseDtuMin $newDTU
    }

    Write-Output "ElasticPools name: $ElasticPoolName"
    Write-Output "ElasticPools current DTU: $currentDTU"
    Write-Output "ElasticPools new DTU: $newDTU"
}
if ($WebhookData) {
    if(-Not $WebhookData.RequestBody)
    {
        $WebhookData = (ConvertFrom-Json -InputObject $WebhookData)
    }
}

if(-Not $WebhookData.RequestBody) {
    write-output "No request body found!"
}

$RequestBody = (ConvertFrom-JSON -InputObject $WebhookData.RequestBody)
if($RequestBody.data.alertContext.SearchResults.tables[0].rows -ne $null) {
    $SearchResultRows = $RequestBody.data.alertContext.SearchResults.tables[0].rows
    foreach ($SearchResultRow in $SearchResultRows) {
        write-output "Processing $SearchResultRow[0]"
        ScaleElasticPool($SearchResultRow[0])
    }

}
