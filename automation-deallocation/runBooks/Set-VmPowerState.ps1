workflow Set-VmPowerState
{
	[cmdletbinding()]
	Param (
		[parameter(Mandatory=$true)]
		[String]
		$PowerState,
		[parameter(Mandatory=$true)]
		[object]
		$vm
	)

	Write-Verbose 'Trying to connect to the Azure'
	$azureAutomationCredential = Get-AutomationPSCredential -Name 'azureCredential'

	if(!$azureAutomationCredential)
	{
		Throw "ERROR: Could not find an Automation Credential Asset named $azureAutomationCredential."
	}

	Add-AzureRmAccount -Credential $azureAutomationCredential -ErrorAction Stop

	Write-Verbose 'Trying to Select Subscription'
	$subscriptionID = Get-AutomationVariable -Name 'azureSubscriptionID'

	if(!$subscriptionID)
	{
		Throw "ERROR: Could not find an Automation Subscription Asset named $subscriptionID."
	}

	Select-AzureRmSubscription -SubscriptionId $subscriptionID -ErrorAction Stop

	try
	{
		$vmPowerState = (Get-AzureRmVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status -errorAction Stop).Statuses | where Code -like "PowerState*" 
		$vmPowerState = $vmPowerState.Code -replace "PowerState/", ""

		If($PowerState -eq "Stop" -and $vmPowerState -ne "deallocated")
		{
			Write-Verbose 'Trying to stop VM as not deallocated'
			$powerOperationStatus = ($vm | Stop-AzureRmVM -Force)
		}
		elseif ($PowerState -eq "Start" -and $vmPowerState -notmatch "running")
		{
			Write-Verbose 'Trying to start VM as not running'
			$powerOperationStatus = ($vm | Start-AzureRmVM)
		}

		if($powerOperationStatus.IsSuccessStatusCode -ine $true)
		{
			$false
		}
		else
		{
			$true
		}
	}
	catch
	{
		THROW $_
	}
}