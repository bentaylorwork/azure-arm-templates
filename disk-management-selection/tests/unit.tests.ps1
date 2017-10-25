Param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullorEmpty()]
    [string]
    $location = 'WestEurope',
    [Parameter(Mandatory = $false)]
    [ValidateNotNullorEmpty()]
    [string]
    $resourceGroupName = (New-Guid).guid,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [hashtable]
    $templateParameterObject,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [string]
    $templateURI
)

$removeResourceGroup = $false

if (-not (Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction SilentlyContinue)){
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location | Out-Null
    $removeResourceGroup = $true
}

Describe "Azure RM Template Disk Selection Tests" {
    $debugPreference = 'Continue'

    Context "Does Template Deploy Correctly" {
        It "Based on the JSON output" {
            $rawResponse = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateURI $TemplateURI -TemplateParameterObject $parameterHash -ErrorAction Stop 5>&1
            $deploymentOutput = ($rawResponse.Item(32) -split 'Body:' | Select-Object -Skip 1 | ConvertFrom-Json).properties

            $deploymentOutput.provisioningState | Should Be 'Succeeded'
        }
    }
    Context "Un-Managed Disks" {
        $parameterHash.diskType = 'unmanaged'
        $rawResponse = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateURI $TemplateURI -TemplateParameterObject $parameterHash -ErrorAction Stop 5>&1
        $deploymentOutput = ($rawResponse.Item(32) -split 'Body:' | Select-Object -Skip 1 | ConvertFrom-Json).properties

        It "Does VM Have The Correct URI" {
            $vm = $deploymentOutput.validatedResources | Where-Object { $_.type -eq 'Microsoft.Compute/virtualMachines' }

            $vm.properties.storageProfile.osDisk.vhd.uri | Should Not Be $null
        }
        It "Does Availability Set Have Correct SKU" {
            $av = $deploymentOutput.validatedResources | Where-Object { $_.type -eq 'Microsoft.Compute/availabilitySets' }

            $av.sku.name | Should Be 'Classic'
        }
        It "Is Storage Account Created" {
            $deploymentOutput.validatedResources | Where-Object { $_.type -eq 'Microsoft.Storage/storageAccounts' } | Should Not Be $null
        }
    }
    Context "Managed Disks" {
        $parameterHash.diskType = 'managed'
        $rawResponse = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateURI $TemplateURI -TemplateParameterObject $parameterHash -ErrorAction Stop 5>&1
        $deploymentOutput = ($rawResponse.Item(32) -split 'Body:' | Select-Object -Skip 1 | ConvertFrom-Json).properties

        It "Does VM Have The Correct URI" {
            $vm = $deploymentOutput.validatedResources | Where-Object { $_.type -eq 'Microsoft.Compute/virtualMachines' }

            $vm.properties.storageProfile.osDisk.vhd.uri | Should Be $null
        }
        It "Does Availability Set Have Correct SKU" {
            $av = $deploymentOutput.validatedResources | Where-Object { $_.type -eq 'Microsoft.Compute/availabilitySets' }

            $av.sku.name | Should Be 'Aligned'
        }
        It "Is Storage Account Created" {
            $deploymentOutput.validatedResources | Where-Object { $_.type -eq 'Microsoft.Storage/storageAccounts' } | Should Be $null
        }
    }

    $debugPreference = 'SilentlyContinue'
}

if($removeResourceGroup -eq $true) {
    Remove-AzureRmResourceGroup -Name $resourceGroupName -Force | Out-Null
}