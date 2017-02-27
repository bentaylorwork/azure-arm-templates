workflow Send-MicrosoftTeamMessage
{
	[cmdletbinding()]
	Param (
		[parameter(Mandatory=$true)]
		[String]
		$message
	)
	
	# Get Teams notification URI.
	$microsoftTeamsNotificationURI = Get-AutomationVariable -Name 'microsoftTeamsNotificationURI'
	
	if(!$microsoftTeamsNotificationURI)
	{
		Throw "ERROR: Could not find an Microsoft Teams Notification URI."
	}
	
	$body = ConvertTo-JSON @{
		text = $message
	}
	
	Invoke-RestMethod -uri $microsoftTeamsNotificationURI -Method Post -body $body -ContentType 'application/json'
}