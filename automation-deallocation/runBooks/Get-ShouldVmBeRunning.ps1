workflow Get-ShouldVmBeRunning
{
	[cmdletbinding()]
	Param (
		[parameter(Mandatory=$true)]
		[String]
		$shutdownStartTime
	)

	try
	{
		if($shutdownStartTime -like "*-*")
		{
			$currentDateTime = Get-Date -errorAction Stop

			$startTime = Get-Date ($shutdownStartTime.split("-").Trim()[0])
			$endTime   = Get-Date ($shutdownStartTime.split("-").Trim()[1])

			Write-Verbose 'Checking if VM should be running or not depending on current tag.'
			If($currentDateTime -ge $startTime -and $currentDateTime -le $endTime)
			{
				$true
			}
			else
			{
				$false
			}
		}
		else
		{
			THROW "ERROR: Tag is possibly in the incorrect format."
		}
	}
	catch
	{
		THROW "ERROR: Get-Date more than likely didn't like the input."
	}
}