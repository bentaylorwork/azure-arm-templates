workflow Invoke-vmDeallocation
{
	Param (
		[parameter(Mandatory=$true)]
		[String]
		$tagKey = "autoShutDownTimes"
	)

	try
	{
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

		Write-Verbose 'Trying to get VMs in the subscription.'
		$vms = Get-AzureRmVM | Where-Object { $_.Tags[$tagKey] }

		ForEach –parallel ($vm in $vms)
		{
			$shutdownStartTime = $vm.Tags.$tagKey

			# if vm has tag
			if($shutdownStartTime)
			{
				$shouldVMBeRunning = Get-ShouldVmBeRunning -shutdownStartTime $shutdownStartTime

				if($shouldVMBeRunning -eq $true)
				{
					$isSuccessful = Set-VmPowerState -powerState "start" -vm $vm
				}
				elseif ($shouldVMBeRunning -eq $false)
				{
					$isSuccessful = Set-VmPowerState -powerState "stop" -vm $vm
				}

				if($isSuccessful -eq $true)
				{
					Send-MicrosoftTeamMessage -message "$($vm.name) - Power State Was Set Successfully"
				}
				else
				{
					Send-MicrosoftTeamMessage -message "$($vm.name) - VM Power State Was Not Set Successfully"
				}
			}
		}
	}
	catch
	{
		Send-MicrosoftTeamMessage -message "*** $($vm.name) - AN EXCEPTION OCCURED ***"
	}
}