# A RDS deployment on a single VM with a seperate AD VM

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbentaylorwork%2Fazure-arm-templates%2Fmaster%2Frds-deployment-singlehost%2Fazuredeploy.json) 
[![Deploy to Azure](http://armviz.io/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fbentaylorwork%2Fazure-arm-templates%2Fmaster%2Frds-deployment-singlehost%2Fazuredeploy.json) 

## Overview
This template creates an AD deployment on a VM it then creates an RDS farm deployment on a seperate VM.

## Notes
It is not best practise to have all RDS roles on a single VM. This template was created for testing.

## Versions
### 1.0.0.0
* Initial release with the following support:
    * Deploys a VM for Active Directory - Roles installed and configured via DSC.
    * Deploys a VM for RDS - Roles installed and configured via DSC.
    
## Known Limitations
* RD Gateway isn't configured - Need time to re-work the DSC resource.

## Contributors
* Ben Taylor - ben@bentaylor.work