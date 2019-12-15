param(
  [string]$ResourceGroupName
)

Describe -Name 'SQL Server' -Fixture {
    Context -Name 'Resource Group' {
        It -name 'Passed Resource Group existence check' -test {
            Get-AzResourceGroup -Name $ResourceGroupName | Should Not Be $null
        }
    }
}