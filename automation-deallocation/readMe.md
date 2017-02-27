# De-Allocation ARM Template

## Overview
Deploys all the resources required to Start and Stop (De-Allocate) ARM VMs based on a tags.

## Required Tags On The VM's To Be De-Allocated?The tag on the VMs should be in the format below. With the tag value being the times the VM should be on.

| Tag Name          | Tag Value   |
| ----------------- |:-----------:|
| autoShutDownTimes | 09:00-17:00 |

## Parameters
* automationAccountName         - The name of the Azure Automation account you want to deploy
* azureSubscriptionId           - The ID of the Azure subscription the VMS are running in
* azureSubscriptionUserName     - The User Name for the Azure Automation credential used to interact with your AzureRM subscription
* azureSubscriptionPassword     - The Password for the Azure Automation credential used to interact with your AzureRM subscription.
* microsoftTeamsNotificationURI - The URI for your Microsoft Teams Notification Channel.
* jobScheduleStartTime          - The time to start the schedule on.  This is a datetime in Automation (2017-12-01T23:59:00+00:00). This also has to be 5 mins in the future.
* jobScheduleGuid"              - The GUID for the job schedule. This identifier links the schedule to the runbook."

## Versions
### 1.0.0.0
* Initial release with the following support:
    * De-allocates VMs based on a time tag.
    * Notifies a Microsoft Team Channel of actions
    
## Known Limitations
* Only works on times and doesn't take into account the day.

## Contributors
* Ben Taylor